// Load the WebAssembly module
const response = await fetch("../wat-wasm/greet.wasm");
const buffer = await response.arrayBuffer();
const module = await WebAssembly.instantiate(buffer);

// Make a Uint8Array view of the memory from 500 to 508 and write the length-prefixed string "Mike" into it
const nameBytes = new Uint8Array(module.instance.exports.memory.buffer, 500, 8);
nameBytes[0] = 4;
nameBytes[1] = 0;
nameBytes[2] = 0;
nameBytes[3] = 0;
nameBytes[4] = 'M'.charCodeAt(0);
nameBytes[5] = 'i'.charCodeAt(0);
nameBytes[6] = 'k'.charCodeAt(0);
nameBytes[7] = 'e'.charCodeAt(0);

// Call the greet function with the pointer to the length-prefixed string
module.instance.exports.greet();

// Get the length-prefixed string from memory location 0
const greetLen = new Uint32Array(module.instance.exports.memory.buffer, 0, 1)[0];
const greetBytes = new Uint8Array(module.instance.exports.memory.buffer, 4, greetLen);

// Decode the string from UTF-8 bytes to a JavaScript string
const greetStr = new TextDecoder('utf-8').decode(greetBytes);

// Display the greeting message
document.getElementById("output").textContent = `OUTPUT: ${greetStr}`;
