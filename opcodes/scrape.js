function run() {
  return $("td[axis]")
    .map(function () {
      var desc = "";
      var val = $(this).attr("axis").split("|");
      var flags = ["C", "N", "P/V", "H", "Z", "S"];

      const data = {
        flags: flags.reduce((acc, curr) => ({ [curr]: "", ...acc }), {}),
      };

      let unaffected = 0;
      for (i = 0; i < 6; i++) {
        let desc = "";

        switch (val[0].charAt(i)) {
          case "-":
            unaffected++;
            desc += "unaffected";
            break;
          case "+":
            desc += "affected as defined";
            break;
          case "P":
            desc += "detects parity";
            break;
          case "V":
            desc += "detects overflow";
            break;
          case "1":
            desc += "set";
            break;
          case "0":
            desc += "reset";
            break;
          case "*":
            desc += "exceptional";
            break;
          default:
            desc += "unknown";
        }

        data.flags[flags[i]] = desc;
      }

      if (unaffected === 6) data.unaffected = true;

      data.operation = $(this).text();
      const [opcode, ...operand] = data.operation.split(/[, ]/);
      data.opcode = opcode;
      data.operand = operand;
      data.code =
        $(this).closest("table").attr("title") +
        "0123456789ABCDEF".charAt($(this).parent().index() - 1) +
        "0123456789ABCDEF".charAt($(this).index() - 1);

      data.bytes = parseInt(val[1], 10);
      data.time = parseInt(val[2], 10);
      data.description = val[3];
      return data;
    })
    .get();
}
