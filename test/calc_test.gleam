import gleeunit
import gleeunit/should
import calc.{ Number, PrecNone, get_prefix_infix_precedence, tokenize, Plus, execute, Add,Sub, Push,Minus,number,compile,PrecTerm,PrecFactor,PrecGreatest, prec_comp}
import gleam/option.{None,Some}
import gleam/io
import gleam/order
import gleam/list

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
// pub fn get_prefix_infix_precedence_test() {
//   Number(1)
//   |> get_prefix_infix_precedence
//   |> should.equal(#(Some(number), None, PrecNone))
// }

// pub fn tokenizer_test() {
//   "-123+1"
//   |> tokenize
//   |> should.equal([Minus,Number(123), Plus, Number(1)])
// }

// pub fn exec_test() {
//   //(1+1)+(1-1)
//   execute([Push(1),Push(1),Add,Push(1),Push(1),Sub,Add], [])
//   |> should.equal([2])
// }

// pub fn precedence_test() {
//   prec_comp(PrecNone,PrecNone) |> should.equal(order.Eq)
//   [PrecTerm, PrecFactor,PrecGreatest]|> list.all(fn(p) {p prec_comp(p,PrecNone) == order.Gt}) |> should.be_true()

//   prec_comp(PrecTerm,PrecTerm) |> should.equal(order.Eq)
//   [PrecNone]|> list.all(fn(p) {p prec_comp(p,PrecTerm) == order.Lt}) |> should.be_true()
//   [PrecFactor,PrecGreatest]|> list.all(fn(p) {p prec_comp(p,PrecTerm) == order.Gt}) |> should.be_true()

//   prec_comp(PrecFactor,PrecFactor) |> should.equal(order.Eq)
//   [PrecNone, PrecTerm]|> list.all(fn(p) {p prec_comp(p,PrecFactor) == order.Lt}) |> should.be_true()
//   [PrecGreatest]|> list.all(fn(p) {p prec_comp(p,PrecFactor) == order.Gt}) |> should.be_true()

//     prec_comp(PrecGreatest,PrecGreatest) |> should.equal(order.Eq)
//   [PrecTerm, PrecFactor,PrecNone]|> list.all(fn(p) {p prec_comp(p,PrecGreatest) == order.Lt}) |> should.be_true()

// }

pub fn simple_test(){
  io.debug("simple_test===============")
    "-3*(4-2)+2"
  |> tokenize
  |> compile
  |> execute([])
  |> should.equal([-4])
}
// pub fn simpler_test(){
//   io.debug("simple_test222222222222222===============")
//     "-3*4+2+2"
//   |> tokenize
//   |> compile
//   |> execute([])
//   |> should.equal([-8])

//   //Neg goes ok, mul in ok spot but then the plus after hmmmmmmmmmmmm should that be in prefix of 1st push of 3? number is unary too ofc
// }