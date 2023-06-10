import gleam/io
import gleam/map
import gleam/iterator
import gleam/string
import gleam/set
import gleam/list
import gleam/option.{None, Some}
import gleam/order

pub fn main() {
  io.println("Hello from calc!")
  // 1. tokenize
  // 2. compile
  // 3. execute
}

// Tokenize
pub type Token {
  Number(Int)
  Plus
  Minus
  Star
  Slash
  BraceOpen
  BraceClose
}

pub fn tokenize(s: String) {
  let allowed =
    [
      "+", "-", "*", "/", "(", ")", "0", "1", "2", "3", "4", "5", "6", "7", "8",
      "9",
    ]
    |> set.from_list

  s
  |> string.to_graphemes
  |> iterator.from_list
  |> iterator.filter(fn(x) {
    allowed
    |> set.contains(x)
  })
  |> iterator.map(fn(x) {
    case x {
      "+" -> Plus
      "-" -> Minus
      "*" -> Star
      "/" -> Slash
      "(" -> BraceOpen
      ")" -> BraceClose
      "0" -> Number(0)
      "1" -> Number(1)
      "2" -> Number(2)
      "3" -> Number(3)
      "4" -> Number(4)
      "5" -> Number(5)
      "6" -> Number(6)
      "7" -> Number(7)
      "8" -> Number(8)
      "9" -> Number(9)
    }
  })
  |> iterator.fold(
    from: [],
    with: fn(acc, element) {
      case element {
        Number(n) ->
          case acc {
            [Number(n1), ..xs] -> [Number(n + 10 * n1), ..xs]
            _ -> [element, ..acc]
          }
        op -> [op, ..acc]
      }
    },
  )
  |> list.reverse()
}

// Compile
// Basically copied from 'crafting interpreters'
pub type Precedence {
  PrecNone
  PrecTerm
  PrecFactor
  PrecGreatest
}

pub fn prec_inc(p) {
  case p {
    PrecNone -> PrecTerm
    PrecTerm -> PrecFactor
    PrecFactor -> PrecGreatest
    _ -> PrecGreatest
  }
}

pub fn prec_comp(p, p1) {
  case #(p, p1) {
    #(PrecNone, PrecNone) -> order.Eq
    #(PrecNone, _) -> order.Lt
    #(_, PrecNone) -> order.Gt
    #(PrecTerm, PrecFactor) -> order.Lt
    #(PrecFactor, PrecTerm) -> order.Gt
    #(PrecGreatest, PrecGreatest) -> order.Eq
    #(PrecGreatest, _) -> order.Gt
    #(_,PrecGreatest) -> order.Lt
    _ -> order.Eq
  }
}

pub fn compile(tokens: List(Token)) -> List(Op) {
  case expression(tokens, []) {
    #([], ops) -> ops //|> list.reverse
  }
}

pub fn expression(tokens: List(Token), ops: List(Op)) {
  parse_precedence(PrecTerm, tokens, ops)
}

pub fn parse_precedence(prec, tokens, ops) {
  case tokens {
    [] -> #([], ops)
    [t, ..] -> {
      case get_prefix_infix_precedence(t) {
        #(Some(prefix_fn), _, new_prec) -> {
          let #(ts1, ops1) = prefix_fn(tokens, ops)
          case ts1 {
            [] -> #([], ops1)
            [t1, ..] -> {
              case prec_comp(new_prec, prec) {
                order.Gt -> { 
                  io.debug("quitting")
                  #(ts1, ops1)}
                _ ->
                  case t1 {
                    BraceClose -> #(ts1, ops1)
                    _ -> {
                      let assert #(_, Some(infix_fn), _) = get_prefix_infix_precedence(t1)
                      infix_fn(ts1, ops1)
                    }
                  }
              }
            }
          }
        }
      }
    }
  }
}

pub fn number(tokens: List(Token), ops: List(Op)) {
  case tokens {
    [Number(n), ..ts] -> #(ts, [Push(n), ..ops])
  }
}

pub fn grouping(tokens: List(Token), ops: List(Op)) {
  case tokens {
    [BraceOpen, ..ts] -> {
      let #([BraceClose, ..ts1], ops1) = expression(ts, ops)
      #(ts1, ops1)
    }
  }
}

pub fn binary(tokens: List(Token), ops: List(Op)) {
  case tokens {
    [t, ..ts] -> {
      let #(_, _, prec) = get_prefix_infix_precedence(t)
      let #(ts1, ops1) = parse_precedence(prec_inc(prec), ts, ops)
      let op = case t {
        Plus -> Add
        Minus -> Sub
        Star -> Mul
        Slash -> Div
        // TODO should not happen, can add results everywhere for feedback but meh.. 
        _ -> Div
      }

      #(ts1, list.append(ops1, [op]))
    }
  }
}

pub fn unary(tokens: List(Token), ops: List(Op)) {
  io.debug("unary")
  case tokens {
    [Minus, ..ts] -> {
      let #(ts1, ops1) = parse_precedence(PrecGreatest,ts, ops)
      #(ts1, list.append(ops1, [Neg]))
    }
  }
}

pub fn get_prefix_infix_precedence(tt: Token) {
  // prefix fn, infix fn, precedence
  let rules =
    map.from_list([
      // #(Number(_), #(Nil, Nil, PrecNone))
      #(Plus, #(None, Some(binary), PrecTerm)),
      #(Minus, #(Some(unary), Some(binary), PrecTerm)),
      #(Star, #(None, Some(binary), PrecFactor)),
      #(Slash, #(None, Some(binary), PrecFactor)),
      #(BraceOpen, #(Some(grouping), None, PrecNone)),
      #(BraceClose, #(None, None, PrecNone)),
    ])

  case map.get(rules, tt) {
    Error(Nil) -> #(Some(number), None, PrecNone)
    Ok(res) -> res
  }
}

// Execute
pub type Op {
  Neg
  Add
  Sub
  Mul
  Div
  Push(Int)
}

pub fn execute(ops: List(Op), stack: List(Int)) {
  io.debug(ops)
  case #(ops, stack) {
    #([], _) -> stack
    #([Push(n), ..ops1], _) -> execute(ops1, [n, ..stack])
    #([Neg, ..ops1], [n, ..stack1]) -> execute(ops1, [-n, ..stack1])
    #([Add, ..ops1], [n1, n2, ..stack1]) -> execute(ops1, [n1 + n2, ..stack1])
    #([Sub, ..ops1], [n1, n2, ..stack1]) -> execute(ops1, [n1 - n2, ..stack1])
    #([Mul, ..ops1], [n1, n2, ..stack1]) -> execute(ops1, [n1 * n2, ..stack1])
    #([Div, ..ops1], [n1, n2, ..stack1]) -> execute(ops1, [n1 / n2, ..stack1])
  }
}
