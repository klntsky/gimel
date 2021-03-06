module Gimel.Sub where

import Prelude

import Data.Foldable (traverse_)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console (logShow)
import Gimel.Cmd (Cmd(..))

data Sub model event
  = Sub (SubInstance model event)
  | Always (model -> Cmd event)
  | Batch (Array (Sub model event))

instance semigroupSub :: Semigroup (Sub model event) where
  append x y = Batch [x, y]

instance monoidSub :: Monoid (Sub model event) where
  mempty = Batch []

instance functorSub :: Functor (Sub model) where
  map f = case _ of
    Sub inst ->
      Sub $ inst
        { enable = \model runEvent ->
            inst.enable model $ runEvent <<< f
        }
    Always runSub -> Always \model -> f <$> runSub model
    Batch subs -> Batch $ map f <$> subs

connect
  :: forall model1 model2 event1 event2
  .  (model2 -> model1)
  -> (event1 -> event2)
  -> Sub model1 event1
  -> Sub model2 event2
connect fModel fEvent = mapSubModel fModel <<< map fEvent

mapSubModel :: forall model1 model2 event. (model2 -> model1) -> Sub model1 event -> Sub model2 event
mapSubModel f = case _ of
  Batch xs -> Batch $ map (mapSubModel f) xs
  Always runSub -> Always \model -> runSub $ f model
  Sub inst ->
    Sub $ inst
      { checkCondition = \model -> inst.checkCondition $ f model
      , enable = \model runEvent -> inst.enable (f model) runEvent
      }

type SubInstance model event =
  { checkCondition :: model -> Boolean
  , enable         :: model -> (event -> Aff Unit) -> Aff (Aff Unit)
  , status         :: SubStatus
  }

data SubStatus
  = Active {disable :: Aff Unit}
  | Inactive

none :: forall model event. Sub model event
none = Batch []

mkSub
  :: forall model event
  .  (model -> (event -> Aff Unit) -> Aff (Aff Unit))
  -> Sub model event
mkSub enable = Sub {checkCondition: const true, enable, status: Inactive}

mkSubEff
  :: forall model event
  .  (model -> (event -> Effect Unit) -> Effect (Effect Unit))
  -> Sub model event
mkSubEff enable =
  Sub
    { checkCondition: const true
    , enable: \model runEvent ->
        liftEffect <$> liftEffect (enable model (launchAff_ <<< runEvent))
    , status: Inactive
    }

enableWhen :: forall model event. (model -> Boolean) -> Sub model event -> Sub model event
enableWhen checkCondition (Sub inst) = Sub inst {checkCondition = checkCondition}
enableWhen _ x = x

logModel :: forall model event. Show model => Sub model event
logModel = Always $ Cmd <<< const <<< logShow

execEvents :: forall model event. Array event -> Sub model event
execEvents events = mkSub \_ runEvent -> traverse_ runEvent events $> mempty

runCmd :: forall model event. Cmd event -> Sub model event
runCmd cmd = runCmds [cmd]

runCmds :: forall model event. Array (Cmd event) -> Sub model event
runCmds cmds = mkSub \_ runEvent -> do
  traverse_ (\(Cmd cmd) -> cmd runEvent) cmds

  pure mempty

execEvent :: forall model event. event -> Sub model event
execEvent e = execEvents [e]