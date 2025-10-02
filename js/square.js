// Load the WebAssembly module
const response = await fetch("../wat-wasm/square.wasm");
const buffer = await response.arrayBuffer();
const module = await WebAssembly.instantiate(buffer);

// Call the square function exported by the WebAssembly module
const result = module.instance.exports.square(5);

// Display the result
document.getElementById("output").textContent = `Square of 5 is ${result}`;
