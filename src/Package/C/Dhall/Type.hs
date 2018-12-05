{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric  #-}

module Package.C.Dhall.Type ( CPkg (..)
                            , ConfigureVars (..)
                            , BuildVars (..)
                            , InstallVars (..)
                            , EnvVar (..)
                            , Command (..)
                            ) where

import qualified Data.Text             as T
import           Dhall
import           GHC.Natural           (Natural)
import           Package.C.Type.Shared

data ConfigureVars = ConfigureVars { installDir   :: T.Text
                                   , targetTriple :: Maybe T.Text
                                   , includeDirs  :: [ T.Text ]
                                   , configOS     :: OS
                                   } deriving (Generic, Inject)

data BuildVars = BuildVars { cpus    :: Natural
                           , buildOS :: OS
                           }
                deriving (Generic, Inject)

data EnvVar = EnvVar { var :: T.Text, value :: T.Text }
            deriving (Generic, Interpret)

data Command = CreateDirectory { dir :: T.Text }
             | MakeExecutable { file :: T.Text }
             | Call { program     :: T.Text
                    , arguments   :: [T.Text]
                    , environment :: Maybe [EnvVar]
                    , procDir     :: Maybe T.Text
                    }
             deriving (Generic, Interpret)

data CPkg = CPkg { pkgName          :: T.Text
                 , pkgVersion       :: [ Natural ]
                 , pkgUrl           :: T.Text
                 , pkgSubdir        :: T.Text
                 , pkgBuildDeps     :: [ Dep ]
                 , pkgDeps          :: [ Dep ]
                 , configureCommand :: ConfigureVars -> [ Command ]
                 , buildCommand     :: BuildVars -> [ Command ]
                 , installCommand   :: InstallVars -> [ Command ]
                 } deriving (Generic, Interpret)
