// Load the WebAssembly module
const response = await fetch("../wat-wasm/greet-alloc.wasm");
const buffer = await response.arrayBuffer();
const module = await WebAssembly.instantiate(buffer);

// Tell the module to allocate 8 bytes of memory for a string "Mike" prefixed with its length
const nameAddress = module.instance.exports.alloc(8);

// Make a Uint8Array view of the allocated memory and write the length-prefixed string "Mike" into it
const nameBytes = new Uint8Array(module.instance.exports.memory.buffer, nameAddress, 8);
nameBytes[0] = 4; // Length of the string "Mike"
nameBytes[1] = 0;
nameBytes[2] = 0;
nameBytes[3] = 0;
nameBytes[4] = 'M'.charCodeAt(0);
nameBytes[5] = 'i'.charCodeAt(0);
nameBytes[6] = 'k'.charCodeAt(0);
nameBytes[7] = 'e'.charCodeAt(0);

// Call the greet function with the pointer to the length-prefixed string
const greetAddress = module.instance.exports.greet(nameAddress);

// Get the length-prefixed string returned by greet
const greetLen = new Uint32Array(module.instance.exports.memory.buffer, greetAddress, 1)[0];
const greetBytes = new Uint8Array(module.instance.exports.memory.buffer, greetAddress + 4, greetLen);

// Decode the string from UTF-8 bytes to a JavaScript string
const greetStr = new TextDecoder('utf-8').decode(greetBytes);

// Display the greeting message
document.getElementById("output").textContent = `OUTPUT: ${greetStr}`;
