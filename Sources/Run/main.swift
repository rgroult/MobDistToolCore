import App

do {
    try app(.detect()).run()
}catch {
    print("Unexpected error :\(error)")
}

