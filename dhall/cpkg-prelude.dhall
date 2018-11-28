let concatMapSep = https://raw.githubusercontent.com/dhall-lang/dhall-lang/master/Prelude/Text/concatMapSep
in

let showVersion =
  λ(x : List Natural) → concatMapSep "." Natural Natural/show x
in

let mkTarget =
  λ(x : Optional Text) →
    Optional/fold Text x Text (λ(tgt : Text) → " --target=${tgt}") ""
in

let OS = < FreeBSD : {}
         | OpenBSD : {}
         | NetBSD : {}
         | Solaris : {}
         | Dragonfly : {}
         | Linux : {}
         | Darwin : {}
         | Windows : {}
         >
in

let makeExe =
  λ(os : OS) →

    let gmake = λ(_ : {}) → "gmake"
    in
    let make  = λ(_ : {}) → "make"
    in

    merge
      { FreeBSD   = gmake
      , OpenBSD   = gmake
      , NetBSD    = gmake
      , Solaris   = gmake
      , Dragonfly = gmake
      , Linux     = make
      , Darwin    = make
      , Windows   = make
      }
      os
in

let ConfigureVars = { installDir : Text, targetTriple : Optional Text, includeDirs : List Text, configOS : OS }
in

let BuildVars = { cpus : Natural, buildOS : OS }
in

let defaultConfigure =
  λ(cfg : ConfigureVars) →
    [ "./configure --prefix=" ++ cfg.installDir ++ mkTarget cfg.targetTriple ]
in

let defaultBuild =
  λ(cfg : BuildVars) →
    [ "${makeExe cfg.buildOS} -j${Natural/show cfg.cpus}"]
in

let defaultInstall =
  λ(os : OS) →
    [ "${makeExe os} install" ]
in

let VersionBound = < Lower : { lower : List Natural }
                   | Upper : { upper : List Natural }
                   | LowerUpper : { lower : List Natural, upper : List Natural }
                   | NoBound : {} >

let Dep = { name : Text, bound : VersionBound }
in

let unbounded =
  λ(x : Text) →
    { name = x
    , bound = VersionBound.NoBound
    }
in

let defaultPackage =
  { configureCommand = defaultConfigure
  , executableFiles  = [ "configure" ]
  , buildCommand     = defaultBuild
  , installCommand   = defaultInstall
  , pkgBuildDeps     = [] : List Dep
  , pkgDeps          = [] : List Dep
  }
in

let makeGnuPackage =
  λ(pkg : { name : Text, version : List Natural}) →
    defaultPackage ⫽
      { pkgName = pkg.name
      , pkgVersion = pkg.version
      , pkgUrl = "https://mirrors.ocf.berkeley.edu/gnu/lib${pkg.name}/lib${pkg.name}-${showVersion pkg.version}.tar.xz"
      , pkgSubdir = "lib${pkg.name}-${showVersion pkg.version}"
      }
in

{ showVersion    = showVersion
, makeGnuPackage = makeGnuPackage
, defaultPackage = defaultPackage
, unbounded      = unbounded
, makeExe        = makeExe
}
