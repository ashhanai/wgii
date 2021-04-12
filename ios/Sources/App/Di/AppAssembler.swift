import Swinject

func appAssembler() -> Assembler {
    Assembler([
        AuthAssembly(),
        GasPriceAssembly(),
        UserAssembly()
    ])
}
