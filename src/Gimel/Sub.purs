module Gimel.Sub where

import Prelude

import Effect (Effect)
import Effect.Class.Console (logShow)

data Sub model event
  = Once (model -> (event -> Effect Unit) -> Effect Unit)
  | Always (model -> (event -> Effect Unit) -> Effect Unit)
  | ActiveWhen (ActiveSubInstance model event)

type ActiveSubInstance model event =
  { check    :: model -> Boolean
  , activate :: model -> (event -> Effect Unit) -> Effect (Effect Unit)
  , status   :: ActiveSubStatus
  }

data ActiveSubStatus
  = Active {stop :: Effect Unit}
  | Inactive

mkActiveSub
  :: forall model event
  .  (model -> (event -> Effect Unit) -> Effect (Effect Unit))
  -> Sub model event
mkActiveSub activate = ActiveWhen {check: const true, activate, status: Inactive}

activeWhen :: forall model event. (model -> Boolean) -> Sub model event -> Sub model event
activeWhen check (ActiveWhen x) = ActiveWhen x {check = check}
activeWhen _ x                  = x

logModel :: forall model event. Show model => Sub model event
logModel = Always \model _ -> logShow model

execEvent :: forall model event. event -> Sub model event
execEvent event = Once \_ runEvent -> runEvent event