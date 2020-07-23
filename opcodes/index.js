const fs = require("fs");
const pdf = require("pdf-parse");

let dataBuffer = fs.readFileSync(process.argv[2]);
let start = false;
const headingFont = "g_d0_f5";
let lastPage = null;
const pages = [];
const ops = {};

function parseText(source) {
  const text = source.split("\n");
  const page = text.shift();
  const operation = text.shift();
  text.shift();
  const effect = text.shift();
  text.shift(); // ignore
  const opCode = text.shift();
  text.shift();
  const operands = text.shift();
  // text.shift();
  // const operand = text.shift();
  // text.shift();
  let desc = "";
  let example = "";
  let s = "";
  let i = 0;

  if (!source.includes("Description\n")) return "";

  // ops[operation] = {
  //   page,
  //   operation,
  //   opCode,
  //   effect,
  //   operands,
  //   desc,
  //   example,
  //   source,
  // };

  while ((s = text.shift()) !== "Description") {
    i++;
    if (i > 1000) {
      console.log("failed on desc find");
      console.log(ops[operation]);

      process.exit(1);
    }
  }

  i = 0;
  while (!(s = text.shift() || "").includes("M Cycle")) {
    desc += s + "\n";
    i++;
    if (i > 1000) {
      console.log("failed on desc");
      console.log(ops[operation]);

      process.exit(1);
    }
  }

  const stats = text.shift(); // useless because we lost the tabs

  i = 0;
  while (source.includes("Example\n") && (s = text.shift()) !== "Example") {
    i++;
    if (i > 1000) {
      console.log("failed on example find");
      console.log(ops[operation]);

      process.exit(1);
    }
  }

  i = 0;
  while ((s = text.shift())) {
    example += s + "\n";
    i++;
    if (i > 1000) {
      console.log("failed on example");
      console.log(ops[operation]);

      process.exit(1);
    }
  }

  ops[operation.toLowerCase()] = {
    page,
    operation,
    opCode,
    effect,
    operands,
    desc,
    example,
  };

  if (!ops[opCode.toLowerCase()])
    ops[opCode.toLowerCase()] = ops[operation.toLowerCase()];
}

function pagerender(pageData) {
  return pageData
    .getTextContent()
    .then((textContent) => {
      let pg = textContent.items.find((_) => /^\d+$/.test(_.str));

      if (pg && pg.str === "71") start = true;

      if (!start) return "";
      let lastY;
      let last;
      let text = [];

      const page = parseInt(pg.str, 10);

      const items = Array.from(textContent.items).sort((a, b) => {
        let ay = a.transform[5] | 0;
        let by = b.transform[5] | 0;
        if (ay === by) {
          if (a.str.indexOf(" ") === -1) {
            // a.transform[4]++;
          }
          return a.transform[4] < b.transform[4] ? -1 : 1;
        }
        return ay < by ? 1 : -1;
      });

      const newPage = items.findIndex((_) => _.fontName === headingFont) !== -1;

      for (let item of items) {
        if (item.str === "UM008011-0816") continue;
        if (item.str === "Z80 Instruction Description") continue;
        if (item.str === "Z80 CPU") continue;
        if (item.str === "User Manual") continue;
        if (item.str === "Z80 Instruction Set") continue;
        const y = item.transform[5] | 0;
        if (lastY == y || !lastY) {
          if (last) {
            if (last.width + last.transform[4] + 10 <= item.transform[4]) {
              text[text.length - 1] += "\t";
            }
          }
          text[text.length - 1] += item.str;
        } else {
          text.push(item.str);
        }
        lastY = y;
        last = item;
        // console.log({ lastY, ...item });
      }
      // text.pop(); // drop the last line
      text = text.join("\n").trim();

      if (newPage) {
        pages.push(page + "\n" + text);
      } else {
        pages[pages.length - 1] += "\n" + text;
      }

      if (page === 197) console.warn(items);

      return { pg, textContent };
    })

    .catch((e) => console.log(e));
}

pdf(dataBuffer, { pagerender })
  .then(function (data) {
    // number of pages
    //   console.log(data.numpages);
    //   // number of rendered pages
    //   console.log(data.numrender);
    //   // PDF info

    pages.forEach((page) => parseText(page));
    console.log(JSON.stringify(ops));
    console.warn(ops.ld);
  })
  .catch((e) => console.log(e));
