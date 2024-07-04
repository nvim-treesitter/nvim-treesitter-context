let i = 0;
let k = 0;
let l = 0;
var list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

switch i {

case let x
where x > 0:







    print("i is greater than 0")
default:







    print("i is not 0")
}

if (i > 0) {











    print("i is greater than 0")
} else if (i < 0 &&
        k < 0 &&
        l > 0) {













    print("i is less than 0")
} else {





}

// for with multiple incrementors
for (j,
    k
    ) in zip(rx,
    ry)
    {










    println(j, k)
}

foo: for i in list {
    print(i)









}



while (
        i < 10
        && k < 2
      ) {











    print(i)
}

repeat {





    defer {
        print(score)








    }



} while (i < 10)

func greet(person: String,
person2: String,
person3: String) -> String {







    let greeting = "Hello, " + person + "!"
    return greeting


}

protocol CornersRoundable {







    func roundCorners()
}

func vend(itemNamed name: String) throws {
    guard let item = inventory[name]
    else {















        throw VendingMachineError.invalidSelection
    }


    guard item.count > 0 else {
        throw VendingMachineError.outOfStock
    }
}


do {
    try buyFavoriteSnack(person: "Alice", vendingMachine: vendingMachine)
    print("Success! Yum.")













} catch VendingMachineError.insufficientFunds(let coinsNeeded,
let coinsDeposited) {














    print("Insufficient funds. Please insert an additional \(coinsNeeded) coins.")
} catch {
    print("Unexpected error: \(error).")
}


// enum is also class
class SomeClass: SomeSuperclass,
FirstProtocol,
AnotherProtocol {





// comment







}










