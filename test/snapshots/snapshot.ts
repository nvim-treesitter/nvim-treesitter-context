interface User {
  name: string;



  id: number;




}
 
class UserAccount {
  name: string;
  id: number;



 
  constructor(name: string, id: number) {
    this.name = name;
    this.id = id;

    for (let i = 0; i < 3; i++) {
        console.log("hello");



    }




  }
}


function wrapInArray(obj: string | string[]) {
  if (typeof obj === "string") {
    return [obj];




  }
  return obj;
}
