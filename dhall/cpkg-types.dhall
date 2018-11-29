let OS = < FreeBSD : {}
         | OpenBSD : {}
         | NetBSD : {}
         | Solaris : {}
         | Dragonfly : {}
         | Linux : {}
         | Darwin : {}
         | Windows : {}
         | Redox : {}
         | NoOs : {}
         >
in

let Arch = < X64 : {}
           | AArch : {}
           | Arm : {}
           | RISCV64 : {}
           | PowerPc : {}
           | PowerPC64 : {}
           | PowerPC64le : {}
           | Sparc64 : {}
           | S390x : {}
           | Alpha : {}
           | M68k : {}
           | Mips : {}
           | MipsEl : {}
           | Mips64 : {}
           | Mips64El : {}
           | X86 : {}
           | SH4 : {}
           | HPPA : {} >
in

let Manufacturer = < Unknown : {}
                   | Apple : {}
                   | IBM : {}
                   | PC : {}
                   >
in

let ABI = < GNU : {}
          | Eabi : {}
          | GNUeabi : {}
          | GNUeabihf : {}
          >
in

let TargetTriple = { arch : Arch
                   , manufacturer : Optional Manufacturer
                   , os : OS
                   , abi : Optional ABI
                   }
in

let ConfigureVars = { installDir : Text
                    , targetTriple : Optional Text
                    , includeDirs : List Text
                    , configOS : OS
                    }
in

let BuildVars = { cpus : Natural, buildOS : OS }
in

let VersionBound = < Lower : { lower : List Natural }
                   | Upper : { upper : List Natural }
                   | LowerUpper : { lower : List Natural, upper : List Natural }
                   | NoBound : {} >

let Dep = { name : Text, bound : VersionBound }
in

{ OS            = OS
, ConfigureVars = ConfigureVars
, BuildVars     = BuildVars
, VersionBound  = VersionBound
, Dep           = Dep
, Arch          = Arch
, Manufacturer  = Manufacturer
, ABI           = ABI
, TargetTriple  = TargetTriple
}
