{ name = "my-project"
, dependencies =
  [ "aff"
  , "console"
  , "effect"
  , "psci-support"
  , "react"
  , "react-dom"
  , "react-mui"
  , "web-html"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
}