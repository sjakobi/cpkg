module Package.C.Type.Vars ( BuildVars (..)
                           ) where

import           Package.C.Triple
import           Package.C.Type.Shared

data BuildVars = BuildVars { installDir   :: FilePath
                           , targetTriple :: Maybe Platform
                           , includeDirs  :: [ FilePath ]
                           , preloadLibs  :: [ FilePath ]
                           , linkDirs     :: [ FilePath ]
                           , binDirs      :: [ FilePath ]
                           , buildOS      :: OS -- ^ See [here](https://gcc.gnu.org/onlinedocs/gccint/Configure-Terms.html) for terminology. This is the OS of the system we are building on.
                           , buildArch    :: Arch
                           , static       :: Bool
                           , cpus         :: Int
                           }
