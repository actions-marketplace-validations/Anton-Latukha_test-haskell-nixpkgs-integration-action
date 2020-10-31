#!/usr/bin/env bash

rev=${rev:-master}

projectDir=$(pwd)
echo "Project directory: $projectDir"
projectDirName=$(basename "$projectDir")
derivationName=integratedDerivation
projectDerivationFile=project-derivation.nix
cd ..
echo "Now directory is: $(pwd)"
cabal2nix ./"$projectDir" > "$projectDerivationFile"
# IDK why, but particularly inside CI Tar complains the stdin not being the tar archive, but then unarchives it, who would have thought.
curl -L "https://github.com/NixOS/nixpkgs/archive/$rev.tar.gz" | tar -xz
nixpkgsDir=nixpkgs-$rev
cd "$nixpkgsDir" || exit 1

integrationPointFile=pkgs/development/haskell-modules/non-hackage-packages.nix

# Remove black lines from the end of the file
sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$integrationPointFile"

# Store the number of lines in the file
lineNumToInsertAt=$(wc -l "$integrationPointFile" | cut -f1 -d' ')

lineToInsert=" $derivationName = self.callPackage ../../../$projectDirName/$projectDerivationFile {};"
# Modify the file
sed -i "$lineNumToInsertAt"'i'"$lineToInsert" "$integrationPointFile"

cat "$projectDir/$projectDerivationFile"
cat "$integrationPointFile"

nix-build . -A "haskellPackages.$derivationName"
