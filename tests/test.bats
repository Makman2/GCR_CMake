#!/usr/bin/env bats

@test "basic test" {
  cd basic

  rm -rf build
  mkdir build
  cd build
  cmake ..
  make
  cd ..

  [ -f "build/resources.gresource.xml" ]
  [ -f "build/resources.gresource" ]

  diff "build/resources.gresource.xml" "snapshots/resources.gresource.xml"
  diff "build/resources.gresource" "snapshots/resources.gresource"
}

@test "COMPRESS_ALL works" {
  cd compress-all

  rm -rf build
  mkdir build
  cd build
  cmake ..
  make
  cd ..

  [ -f "build/resources.gresource.xml" ]
  [ -f "build/resources.gresource" ]

  diff "build/resources.gresource.xml" "snapshots/resources.gresource.xml"
  diff "build/resources.gresource" "snapshots/resources.gresource"
}

@test "EMBED_C type-option works" {
  cd create-c-code

  rm -rf build
  mkdir build
  cd build
  cmake ..
  make
  cd ..

  [ -f "build/resources.gresource.xml" ]
  [ -f "build/resources.c" ]

  diff "build/resources.gresource.xml" "snapshots/resources.gresource.xml"
  diff "build/resources.c" "snapshots/resources.c"
}

@test "setting TARGET to a custom value works" {
  cd custom-target

  rm -rf build
  mkdir build
  cd build
  cmake ..
  make
  cd ..

  [ -f "build/resources.gresource.xml" ]
  [ -f "build/custom-resources.gresource" ]

  diff "build/resources.gresource.xml" "snapshots/resources.gresource.xml"
  diff "build/custom-resources.gresource" "snapshots/custom-resources.gresource"
}

@test "extended test" {
  cd extended

  rm -rf build
  mkdir build
  cd build
  cmake ..
  make
  cd ..

  [ -f "build/resources.gresource.xml" ]
  [ -f "build/resources.gresource" ]

  diff "build/resources.gresource.xml" "snapshots/resources.gresource.xml"
  diff "build/resources.gresource" "snapshots/resources.gresource"
}

@test "TOPIXDATA_ALL works" {
  cd topixdata-all

  rm -rf build
  mkdir build
  cd build
  cmake ..
  make
  cd ..

  [ -f "build/resources.gresource.xml" ]
  [ -f "build/resources.gresource" ]

  diff "build/resources.gresource.xml" "snapshots/resources.gresource.xml"
  diff "build/resources.gresource" "snapshots/resources.gresource"
}
