{-# LANGUAGE RankNTypes #-}

-- TODO: a lot of the stuff in this module could be made pure so that it only
-- gets called once
module Package.C.Db.Register ( registerPkg
                             , cPkgToDir
                             , globalPkgDir
                             , printCompilerFlags
                             , printLinkerFlags
                             , printPkgConfigPath
                             , packageInstalled
                             , unregisterPkg
                             , allPackages
                             ) where

import           CPkgPrelude
import           Data.Binary          (decode, encode)
import qualified Data.ByteString      as BS
import qualified Data.ByteString.Lazy as BSL
import           Data.Hashable        (Hashable (hash))
import qualified Data.Set             as S
import           Numeric              (showHex)
import           Package.C.Db.Type
import           Package.C.Error
import           Package.C.Type       hiding (Dep (name))

type FlagPrint = forall m. MonadIO m => BuildCfg -> m String

allPackages :: IO [String]
allPackages = do
    (InstallDb index) <- strictIndex
    pure (buildName <$> toList index)

printCompilerFlags :: String -> Maybe String -> IO ()
printCompilerFlags = printFlagsWith buildCfgToCFlags

printLinkerFlags :: String -> Maybe String -> IO ()
printLinkerFlags = printFlagsWith buildCfgToLinkerFlags

printPkgConfigPath :: String -> Maybe String -> IO ()
printPkgConfigPath = printFlagsWith buildCfgToPkgConfigPath

printFlagsWith :: FlagPrint -> String -> Maybe String -> IO ()
printFlagsWith f name host = do

    maybePackage <- lookupPackage name host

    case maybePackage of
        Nothing -> indexError name
        Just p  -> putStrLn =<< f p

-- TODO: do something more sophisticated; allow packages to return their own
-- dir?
buildCfgToLinkerFlags :: MonadIO m => BuildCfg -> m String
buildCfgToLinkerFlags = fmap (("-L" ++) . (</> "lib")) . buildCfgToDir

buildCfgToCFlags :: MonadIO m => BuildCfg -> m String
buildCfgToCFlags = fmap (("-I" ++) . (</> "include")) . buildCfgToDir

buildCfgToPkgConfigPath :: MonadIO m => BuildCfg -> m String
buildCfgToPkgConfigPath = fmap (</> "lib" </> "pkgconfig") . buildCfgToDir

strictIndex :: MonadIO m => m InstallDb
strictIndex = do

    indexFile <- pkgIndex
    -- Add some proper error handling here
    existsIndex <- liftIO (doesFileExist indexFile)

    if existsIndex
        then decode . BSL.fromStrict <$> liftIO (BS.readFile indexFile)
        else pure mempty

packageInstalled :: MonadIO m
                 => CPkg
                 -> Maybe Platform
                 -> BuildVars
                 -> m Bool
packageInstalled pkg host b = do

    indexContents <- strictIndex

    pure (pkgToBuildCfg pkg host b `S.member` _installedPackages indexContents)

lookupPackage :: MonadIO m => String -> Maybe Platform -> m (Maybe BuildCfg)
lookupPackage name host = do

    indexContents <- strictIndex

    let matches = S.filter (\pkg -> buildName pkg == name && targetArch pkg == host) (_installedPackages indexContents)

    pure (S.lookupMax matches)

unregisterPkg :: MonadIO m
              => CPkg
              -> Maybe Platform
              -> BuildVars
              -> m ()
unregisterPkg cpkg host b = do

    indexFile <- pkgIndex
    indexContents <- strictIndex

    let buildCfg = pkgToBuildCfg cpkg host b
        newIndex = over installedPackages (S.delete buildCfg) indexContents

    liftIO $ BSL.writeFile indexFile (encode newIndex)

-- TODO: replace this with a proper/sensible database
registerPkg :: MonadIO m
            => CPkg
            -> Maybe Platform
            -> BuildVars
            -> m ()
registerPkg cpkg host b = do

    indexFile <- pkgIndex
    indexContents <- strictIndex

    let buildCfg = pkgToBuildCfg cpkg host b
        newIndex = over installedPackages (S.insert buildCfg) indexContents

    liftIO $ BSL.writeFile indexFile (encode newIndex)

pkgToBuildCfg :: CPkg
              -> Maybe Platform
              -> BuildVars
              -> BuildCfg
pkgToBuildCfg (CPkg n v _ _ _ _ cCmd bCmd iCmd) host bVar =
    BuildCfg n v mempty mempty host (cCmd bVar) (bCmd bVar) (iCmd bVar) -- TODO: fix pinned build deps &c.

pkgIndex :: MonadIO m => m FilePath
pkgIndex = (</> "index.bin") <$> globalPkgDir

globalPkgDir :: MonadIO m => m FilePath
globalPkgDir = liftIO (getAppUserDataDirectory "cpkg")

platformString :: Maybe Platform -> (FilePath -> FilePath -> FilePath)
platformString Nothing  = (</>)
platformString (Just p) = \x y -> x </> p </> y

buildCfgToDir :: MonadIO m => BuildCfg -> m FilePath
buildCfgToDir buildCfg = do
    global <- globalPkgDir
    let hashed = showHex (abs (hash buildCfg)) mempty
        (<?>) = platformString (targetArch buildCfg)
    pure (global <?> buildName buildCfg ++ "-" ++ showVersion (buildVersion buildCfg) ++ "-" ++ hashed)

cPkgToDir :: MonadIO m
          => CPkg
          -> Maybe Platform
          -> BuildVars
          -> m FilePath
cPkgToDir = buildCfgToDir .** pkgToBuildCfg
