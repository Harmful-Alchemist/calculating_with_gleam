import gleeunit
import gleeunit/should
import calc.{ Number, PrecNone, get_prefix_infix_precedence, tokenize, Plus, execute, Add,Sub, Push,Minus,number,compile}
import gleam/option.{None,Some}
import gleam/io

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
// pub fn get_prefix_infix_precedence_test() {
//   Number(1)
//   |> get_prefix_infix_precedence
//   |> should.equal(#(Some(number), None, PrecNone))
// }

pub fn tokenizer_test() {
  "-123+1"
  |> tokenize
  |> should.equal([Minus,Number(123), Plus, Number(1)])
}

pub fn exec_test() {
  //(1+1)+(1-1)
  execute([Push(1),Push(1),Add,Push(1),Push(1),Sub,Add], [])
  |> should.equal([2])
}


pub fn simple_test(){
  io.debug("simple_test===============")
    "-3*(4-2)+2"
  |> tokenize
  |> compile
  |> execute([])
  |> should.equal([-4])
}