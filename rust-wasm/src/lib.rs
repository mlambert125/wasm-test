use wasm_bindgen::prelude::*;
use web_sys::window;

#[wasm_bindgen]
#[derive(Debug)]
pub struct Person {
    name: String,
    pub age: u32,
}

#[wasm_bindgen]
impl Person {
    #[wasm_bindgen(getter)]
    pub fn name(&self) -> String {
        self.name.clone()
    }

    #[wasm_bindgen(setter)]
    pub fn set_name(&mut self, name: String) {
        self.name = name;
    }
}

#[wasm_bindgen]
pub fn make_person(name: &str, age: u32) -> Person {
    let p = Person {
        name: name.to_string(),
        age,
    };
    window()
        .unwrap()
        .document()
        .unwrap()
        .get_element_by_id("output")
        .unwrap()
        .set_inner_html(&format!("PERSON: {p:?}"));
    p
}
