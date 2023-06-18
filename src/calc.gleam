import gleam/map
import gleam/iterator
import gleam/string
import gleam/set
import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/int

pub fn run(s) {
  // `gleam shell`
  // `calc:run("1+1").`
  s
  |> tokenize
  |> compile
  |> execute([])
  |> hd
}

pub fn hd(xs) {
  let assert [x, ..] = xs
  x
}

// Tokenize
pub type Token {
  Number(Int)
  Plus
  Minus
  Star
  Slash
  ParenOpen
  ParenClose
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
  |> iterator.index
  |> iterator.filter(fn(x) {
    allowed
    |> set.contains(x.1)
  })
  |> iterator.map(fn(x) {
    case x.1 {
      "+" -> #(Plus, x.0)
      "-" -> #(Minus,x.0)
      "*" -> #(Star,x.0)
      "/" -> #(Slash,x.0)
      "(" -> #(ParenOpen,x.0)
      ")" -> #(ParenClose,x.0)
      "0" -> #(Number(0), x.0)
      "1" -> #(Number(1),x.0)
      "2" -> #(Number(2),x.0)
      "3" -> #(Number(3),x.0)
      "4" -> #(Number(4),x.0)
      "5" -> #(Number(5),x.0)
      "6" -> #(Number(6),x.0)
      "7" -> #(Number(7),x.0)
      "8" -> #(Number(8),x.0)
      "9" -> #(Number(9),x.0)
    }
  })
  |> iterator.fold(
    from: [],
    with: fn(acc, element) {
      case element {
        #(Number(n),_i) ->
          case acc {
            [#(Number(n1), i1), ..xs] -> [#(Number(n + 10 * n1), i1), ..xs]
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
    PrecGreatest -> PrecGreatest
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
    #(_, PrecGreatest) -> order.Lt
    _ -> order.Eq
  }
}

pub fn compile(tokens: List(#(Token,Int))) -> List(Op) {
  // io.debug("compile")
  let assert Ok(#([], ops)) = expression(tokens, []) //TODO
  ops
  |> list.reverse
}

pub fn expression(tokens: List(#(Token,Int)), ops: List(Op)) -> Result(#(List(#(Token,Int)), List(Op)), error) {
  // io.debug("expression")
  parse_precedence(PrecTerm, tokens, ops) 
}

pub fn parse_precedence(prec, tokens, ops) -> Result(#(List(#(Token,Int)), List(Op)), error) {
  // io.debug("parse_precedence")
  case tokens {
    // [] -> #([], ops)
    [#(t,_), ..] -> {
      // io.debug(t)
      // io.debug("ehm...... if we stop here we have no prefix fn for:")
      // io.debug(t)

      let assert #(Some(prefix_fn), _, _) = get_prefix_infix_precedence(t)
      let assert Ok(#(ts1, ops1)) = prefix_fn(tokens, ops)

      parse_infixes(prec, ts1, ops1)
    }
  }
}

pub fn parse_infixes(prec, tokens, ops) {
  // io.debug("parse_infixes with prio:")
  // io.debug(prec)
  case tokens {
    [] -> Ok(#([], ops)) //TODO check!
    [#(t,_), ..] -> {
      // io.debug("and token")
      // io.debug(t)
      case get_prefix_infix_precedence(t) {
        #(_, Some(infix_fn), prec1) ->
          case prec_comp(prec, prec1) {
            order.Gt -> {
              Ok(#(tokens, ops))
            }
            _ -> {
              let assert Ok(#(ts2, ops2)) = infix_fn(tokens, ops)
              parse_infixes(prec, ts2, ops2)
            }
          }
        _ -> Ok(#(tokens, ops))
      }
    }
  }
  //closing brace
}

pub fn number(tokens: List(#(Token,Int)), ops: List(Op)) {
  // io.debug("number")
  case tokens {
    [#(Number(n),_i), ..ts] -> Ok(#(ts, [Push(n), ..ops]))
    _ -> Error("Expected a number.")
  }
}

pub fn grouping(tokens: List(#(Token,Int)), ops: List(Op)) {
  // io.debug("grouping")
  case tokens {
    [#(ParenOpen,i), ..ts] -> {
      case  expression(ts, ops) {
       Ok(#([#(ParenClose,_), ..ts1], ops1)) -> Ok(#(ts1, ops1))
       Error(e) -> Error(e)
       _ -> Error("Brace at pos " |> string.append(int.to_string(i)) |> string.append(" is not closed."))
      }

      // io.debug("end grouping")
      
    }
  }
}

pub fn binary(tokens: List(#(Token,Int)), ops: List(Op)) {
  // io.debug("binary")
  case tokens {
    // [] -> #([], ops) TODO check if needed
    [#(t,_), ..ts] -> {
      let #(_, _, prec) = get_prefix_infix_precedence(t)
      // io.debug("binary after precedence:")
      // io.debug(prec)
      let assert Ok(#(ts1, ops1)) = parse_precedence(prec_inc(prec), ts, ops)
      // io.debug("bin after looking")
      let op = case t {
        Plus -> Add
        Minus -> Sub
        Star -> Mul
        Slash -> Div
        // TODO should not happen, can add results everywhere for feedback but meh.. 
        _ -> Div
      }

      Ok(#(ts1, [op, ..ops1]))
    }
  }
}

pub fn unary(tokens: List(#(Token,Int)), ops: List(Op)) {
  // io.debug("unary")
  case tokens {
    [#(Minus,_), ..ts] -> {
      let assert Ok(#(ts1, ops1)) = parse_precedence(PrecGreatest, ts, ops) //TODO prop error
      Ok(#(ts1, [Neg, ..ops1]))
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
      #(ParenOpen, #(Some(grouping), None, PrecNone)),
      #(ParenClose, #(None, None, PrecNone)),
    ]
    )

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
  // io.debug(ops)
  // io.debug(stack)
  case #(ops, stack) {
    #([], _) -> stack
    #([Push(n), ..ops1], _) -> execute(ops1, [n, ..stack])
    #([Neg, ..ops1], [n, ..stack1]) -> execute(ops1, [-n, ..stack1])
    #([Add, ..ops1], [n1, n2, ..stack1]) -> execute(ops1, [n2 + n1, ..stack1])
    #([Sub, ..ops1], [n1, n2, ..stack1]) -> execute(ops1, [n2 - n1, ..stack1])
    #([Mul, ..ops1], [n1, n2, ..stack1]) -> execute(ops1, [n2 * n1, ..stack1])
    #([Div, ..ops1], [n1, n2, ..stack1]) -> execute(ops1, [n2 / n1, ..stack1])
  }
}
