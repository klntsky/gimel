{ name = "my-project"
, dependencies =
  [ "aff"
  , "affjax"
  , "argonaut"
  , "argonaut-codecs"
  , "console"
  , "css"
  , "effect"
  , "filterable"
  , "js-timers"
  , "ordered-collections"
  , "psci-support"
  , "react"
  , "react-dom"
  , "web-html"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
}
