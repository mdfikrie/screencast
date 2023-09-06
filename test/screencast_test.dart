void main(){
  var singleInstance1 = SingleInstance.instance;
  var singleInstance2 = SingleInstance.instance;
  // singleInstance1.changeName(name: "Dzul");
  print(singleInstance2.name);

}

class SingleInstance {
  var name = "";
  SingleInstance._(){
    name = "Fikri";
  }

  static final SingleInstance instance = SingleInstance._();

  void changeName({String? name}){
    this.name = name!;
  }

}