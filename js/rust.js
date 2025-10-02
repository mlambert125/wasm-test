// Import the wasm-pack generated JavaScript bindings
import init, { make_person } from '../rust-wasm/pkg/rust_wasm.js';

// Initialize the wasm-pack module
await init();

// Call the wrapped make_person function and display the result
const person = make_person("Alice", 30);
document.getElementById("output").textContent = `Name: ${person.name}, Age: ${person.age}`;
