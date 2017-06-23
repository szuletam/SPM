describe("Grid context", function () {
  it("should merge two lists 100-times", function () {
    var contextClass = ysy.pro.grid_context;
    var maxLength = 100;
    for (var i = 0; i < 100; i++) {
      var array1 = [];
      var array2 = [];
      for (var j = 0; j < maxLength; j++) {
        if (Math.random() < 0.6) {
          array1.push(j);
        }
        if (Math.random() < 0.6) {
          array2.push(j);
        }
      }
      expect(array1.length).toBeGreaterThan(maxLength * 0.2);
      expect(array2.length).toBeGreaterThan(maxLength * 0.2);
      var result = contextClass.mergeOrder(array1, array2);
      expect(result.length).not.toBeLessThan(array1.length);
      expect(result.length).not.toBeLessThan(array2.length);
      var lastIndex = -1;
      for (j = 0; j < array1.length; j++) {
        var item = array1[j];
        var index = result.indexOf(item);
        expect(index).toBeGreaterThan(lastIndex);
        lastIndex = index;
      }
      for(j=0;j<result.length;j++){
        item = result[j];
        index = result.indexOf(item,j+1);
        expect(index).toEqual(-1);
      }
    }
  });
  it("should ",function(){
    var contextClass = ysy.pro.grid_context;
    var jsons = [
      {
        form_attributes: {
          available_priorities: [
            {name: "Jedna", value: 1},
            {name: "Dva", value: 2},
            {name: "Tři", value: 3},
            // {name:"Čtyři",value:4},
            {name: "Pět", value: 5},
            {name: "Šest", value: 6}
          ]
        }
      },
      {
        form_attributes: {
          available_priorities: [
            {name: "Jedna", value: 1},
            // {name:"Dva",value:2},
            {name: "Tři", value: 3},
            // {name:"Čtyři",value:4},
            {name: "Pět", value: 5},
            {name: "Šest", value: 6}
          ]
        }
      },
      {
        form_attributes: {
          available_priorities: [
            {name: "Jedna", value: 1},
            {name: "Dva", value: 2},
            {name: "Tři", value: 3},
            {name: "Čtyři", value: 4},
            {name: "Pět", value: 5}
            // {name:"Šest",value:6}
          ]
        }
      }
    ];
    var gatheredData = {};
    for (var i = 0; i < jsons.length; i++) {
      contextClass.combineAvailable(gatheredData, jsons[i]);
    }
    var out = contextClass.prepareContextOut(gatheredData, []);
    var options = out[0].folder;
    expect(options.length).toBe(6);
    expect(options[0].isDisabled).toBe(false);
    expect(options[1].isDisabled).toBe(true);
    expect(options[2].isDisabled).toBe(false);
    expect(options[3].isDisabled).toBe(true);
    expect(options[4].isDisabled).toBe(false);
    expect(options[5].isDisabled).toBe(true);
  });
});