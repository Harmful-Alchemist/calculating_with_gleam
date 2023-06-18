import gleeunit
import gleeunit/should
import calc.{
  Add, Minus, Number, Plus, PrecFactor, PrecGreatest, PrecNone, PrecTerm, Push,
  Sub, compile, execute, execute_res, prec_comp, tokenize,
}
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

pub fn tokenizer_test() {
  "-123+1"
  |> tokenize
  |> should.equal([#(Minus, 0), #(Number(123), 1), #(Plus, 4), #(Number(1), 5)])
}

pub fn exec_test() {
  //(1+1)+(1-1)
  execute([Push(1), Push(1), Add, Push(1), Push(1), Sub, Add], [])
  |> should.equal([2])
}

pub fn precedence_test() {
  prec_comp(PrecNone, PrecNone)
  |> should.equal(order.Eq)
  [PrecTerm, PrecFactor, PrecGreatest]
  |> list.all(fn(p) {
    p
    prec_comp(p, PrecNone) == order.Gt
  })
  |> should.be_true()

  prec_comp(PrecTerm, PrecTerm)
  |> should.equal(order.Eq)
  [PrecNone]
  |> list.all(fn(p) {
    p
    prec_comp(p, PrecTerm) == order.Lt
  })
  |> should.be_true()
  [PrecFactor, PrecGreatest]
  |> list.all(fn(p) {
    p
    prec_comp(p, PrecTerm) == order.Gt
  })
  |> should.be_true()

  prec_comp(PrecFactor, PrecFactor)
  |> should.equal(order.Eq)
  [PrecNone, PrecTerm]
  |> list.all(fn(p) {
    p
    prec_comp(p, PrecFactor) == order.Lt
  })
  |> should.be_true()
  [PrecGreatest]
  |> list.all(fn(p) {
    p
    prec_comp(p, PrecFactor) == order.Gt
  })
  |> should.be_true()

  prec_comp(PrecGreatest, PrecGreatest)
  |> should.equal(order.Eq)
  [PrecTerm, PrecFactor, PrecNone]
  |> list.all(fn(p) {
    p
    prec_comp(p, PrecGreatest) == order.Lt
  })
  |> should.be_true()
}

pub fn simple_test() {
  "-3*(4-2)+2"
  |> tokenize
  |> compile
  |> execute_res
  |> should.equal(Ok([-4]))
}

pub fn simpler_test() {
  "-3*4+2+2"
  |> tokenize
  |> compile
  |> execute_res
  |> should.equal(Ok([-8]))
}

pub fn simple2_test() {
  "(4-2)+(2+0)"
  |> tokenize
  |> compile
  |> execute_res
  |> should.equal(Ok([4]))
}

pub fn error1_test() {
  "1+"
  |> tokenize
  |> compile
  |> execute_res
  |> should.equal(Error("Premature end of expression."))
}

pub fn error2_test() {
  "+1"
  |> tokenize
  |> compile
  |> execute_res
  |> should.equal(Error("Expected '-' of a number at pos: 0"))
}

pub fn error3_test() {
  "(+1"
  |> tokenize
  |> compile
  |> execute_res
  |> should.equal(Error("Expected '-' of a number at pos: 1"))
}

pub fn error4_test() {
  "(1+1"
  |> tokenize
  |> compile
  |> execute_res
  |> should.equal(Error("Parenthesis at pos 0 is not closed."))
}

pub fn error5_test() {
  "-"
  |> tokenize
  |> compile
  |> execute_res
  |> should.equal(Error("Premature end of expression."))
}
