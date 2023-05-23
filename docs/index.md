---
header-includes:
    - \usepackage{hyperref}

geometry:
  - top=20mm
  - bottom=20mm
  - left=20mm
  - right=20mm
  - heightrounded

hyperrefoptions:
  - linktoc=all
  - pdfwindowui
  - pdfpagemode=FullScreen

papersize: a4
fontsize: 13pt
listings-no-page-break: true
disable-header-and-footer: true
colorlinks: true
linkcolor: gray
urlcolor: gray
links-as-notes: true
toc-own-page: true
...

# Introduction

Methan0l is an embeddable general-purpose multi-paradigm interpreted programming language.  

Every Methan0l program is a **unit** - a scoped block of expressions that can return a value.  

Expressions can be either separated by a newline character, semicolon or just a space:  

```{.numberLines}
foo = 2; bar = 5

/* Valid too */
calc = foo * bar bar += 123

%% calc
```

# Evaluation and Execution

There are no statements in Methan0l because almost everything yields a value upon evaluation. However, there are two ways expressions can be used: they can be either **evaluated** or **executed**.  

**Evaluation** of an expression yields a value, while **execution** doesn't yield anything and leaves a side effect instead.  

Top-level expressions are **executed** by the interpreter while expressions that are used as parts of other expressions get **evaluated** for the result to be used in the parent expression.  

**Execution** and **evaluation** are equivalent for almost all expressions, except for:  
\
**Unit definition**  

```{.numberLines}
{
	do_something()
}
```  

If a unit definition expression is used inside another expression, it just evaluates to a unit object, while if it's used as a top-level expression, it's evaluated to a unit and the result is immediately executed).  
\
**Identifier expression**  

```{.numberLines}
some_variable
```

When used as a top-level expression, identifier is resolved and if it's bound to a unit, the unit will get executed. If it's bound to an unevaluated expression, it will get evaluated as a result.

# Data Types

All methan0l variables are 3 pointers wide (24 bytes on 64-bit machines) regardless of their type.  

## Primitives & Heap-stored Types

There are two categories of types in Methan0l:  

* Primitives, which are stored entirely within the variables.
* Heap-stored, for which only refcounted pointers to the actual objects are stored within the variables, the objects' contents are stored in the interpreter heap.  

Because of this, copying of values is also separated into two types:  

* Partial copy: only the variable itself is copied (this is equivalent to full copy for primitive types / only the pointer to an object is copied for heap-stored types).  
* Full copy: a new copy of the heap-stored object is allocated along with a new variable that contains a pointer to this object.  

## Type References

Types can be referenced by name using the following expression: `(TypeName)`. Type reference expressions yield numeric type ids, which can be used for type checking (for example, via the `val is: type_expr` operator), type assertions (`obj require: ClassName`), or for comparison with another objects' type ids, which can be obtained via the `typeid: obj` operator.

## Built-in Data Types

All types listed in this section are "magic" built-in non-class types.  

### Primitive Types

**Nil**  

Represents absence of value.  
This is the value type of `nil` reserved identifier as well as the return type of a non-returning function.  

**Integer**  

64-bit integral type.  
Supports hex (`0x123`) and binary (`0b0110101`) literal formats. Digits of numbers can be delimited with spaces for readability (e.g. `x = 1 000 000`)  

**Float**  

64-bit floating point type.  

**Boolean**  

Logical type. Can have values `true` or `false`.  

**Character**  

Character type. Literal format: `'c'`, escape sequences are supported: `'\n'`, ...  

**Reference**  

Points at another value and is always evaluated to it.  
Doesn't have a type id. To check whether value is a reference, use the `is_reference: expr` operator.  
References must always be assigned to variables and returned from functions explicitly (by using the `**expr` operator), otherwise even if `expr` evaluates to a reference, it will be unwrapped into a copy of the referenced value.

### Heap-stored Types

### Callables

**Unit**  

An expression block that may or may not return a value. Can be defined via the `{...}` syntax. Units can also be assigned to variables and invoked the same way as functions.  

**Function**  

Function type. For definition syntax, see the [functions](#functions) section.

### User-defined Types

**Object**  

Represents an object of some class (or an anonymous class). Doesn't have a type id.  
Objects are created via the `new: Class(...)` operator. Copying rules don't apply to them, so to create a full copy of an object, `objcopy: expr` operator must be used.  

**Fallback**  

Represents an object of an unknown native type.  
Used for interfacing with modules and objects of native classes bound to the interpreter.  

### Unevaluated Expressions

#### Expression

Value type returned by the `noeval: expr` operator. When evaluated, evaluates the underlying expression.  

## Standard Classes

#### String
String class. Escape sequences are supported inside literals (e.g. `"a, b \n c\td"`).

#### List
Array-like container class.  
Can be defined via the `[...]` operator (e.g. `list = [1, 2, 3]`), or by invoking the constructor: `list = new: List()`.  

#### Set
A container class without duplicate elements.  
Can be defined by passing a list to the constructor: `new: Set(list_obj)`.  

#### Map
Associative key-value container class.  
Can be defined via the `@[key1 => value1, key2 => value2, ...]` syntax or by invoking the constructor: `map = new: Map()`.  

For more detailed infornation on usage of container types, see the [container types](#container-classes) section.

# Variables

Variables are dynamically-typed and are associated with identifiers.  
In methan0l (almost) anything can be assigned to a variable, including functions, units (headless functions) and even unevaluated expressions.
In terms of visibility variables are divided into two categories: **local** and **global**.  

# Visibility Scopes

All variables in Methan0l are implicitly local.  
This means that for any **regular unit** (a function or a plain unit) any variable defined outside of its scope is **global** while variables defined inside of its scope are **local**.  
**Weak units** (loops, conditional / try-catch expressions, lambdas) have a different visibility rule: all variables from parent scopes up to the first **regular unit** are local and all the other ones are global.  

## Local Variables

**Local** variables can be accessed just by referencing their names:  

```{.numberLines}
{
	x = 123
	foo(x) /* Access local variable x */
}
```

There's also a way to define an explicitly local variable inside of the current scope.  
`var: name` - creates a local variable `name` and returns a reference to it.  
Even though multiple variables with the same name inside nested scopes can be created this way, the `#` prefix will be referring only to the first outer variable with the given name effectively shadowing all the other ones.  

\
Example:  

@EXEC(cat $METHAN0L_HOME/examples/scopes/explicit-locals.mt0)

Output:  

@EXEC(methan0l $:/examples/scopes/explicit-locals.mt0)

## Global Variables

**Global** variables can be accessed either by using the `#` prefix before the variable name:  

```{.numberLines}
x = "global value"
f = func: () {
	x = "local value"
	foo(#x) /* Access x from the outer scope */
}
```

Or by importing them into the current scope by reference via the `global` operator:  

```{.numberLines}
global: var1, var2, ...
var1.foo()
```

**Global** variables can also be captured inside function parameter list definitions after all arguments (similar to default argument definition):  

```{.numberLines}
f = func: x, y, %glob1, %glob2, ... {
	glob1 = x + y; /* Modifies the global `glob1` by reference */
}
```

## Class Visibility Rules

As for classes, object fields can be accessed using `this` reference from within the method definition bodies.  
All the other visibility rules are applied without changes.  

Example:  

@EXEC(cat $METHAN0L_HOME/examples/scopes/classes.mt0)

Output:  

@EXEC(methan0l $:/examples/scopes/classes.mt0)

## Function Invocation Rules

Scope visibility rules don't apply to invocation expressions (`e.g. foo()`).  
If function being called doesn't exist in the current scope, an additional lookup will be performed until it's found. If it's not defined even in the global scope, an exception will be thrown.  

# Reserved Identifiers

Methan0l has a number of reserved identifiers:  

* `nil` -- evaluates to a Nil object, which represents an empty value.
* `newl` -- evaluates to the newline character.
* `true` and `false` -- evaluate to their respective **Boolean** values.

# Comments

There's only one type of comments supported:  

`/* Comment text */`  

# Operators

Most Methan0l operators have traditional behavior that doesn't differ from any other language.  
Operator expressions can also be grouped using `(` `)`.  

## Operator Precedence

The higher the precedence level is, the tighter the operators are bound to their operands.

| Pecedence      | Operators |
| ----------- | ----------- |
|1| `noeval`|
|2| `<%`, `%%`, `%>`|
|3| `+=`, `-=`, `*=`, `/=`, ...|
|4| `=`, `<-`, `:=`|
|5| `::`|
|6| `e1 ? e2 : e3`|
|7| <code>&#124;&#124;</code>|
|8| `&&`|
|9| <code>&#124;</code>|
|10| `^`|
|11| `&`|
|12| `==`, `!=`|
|13| `>`, `<`, `<=`, `>=`|
|14| `>>`, `<<`|
|15| `+`, `-`|
|16| `*`, `/`, `%`|
|17| `-`, `!`, `~` (prefix)|
|18| `++`, `--` (prefix)|
|19| Postfix|
|20| `.`, `@`|
|21| `[]`|
|22| `()`|
|23| `++`, `--` (postfix)|
|24| `var`|

## Assignment Operators

### Copy Assignment

```{.numberLines}
dest_expr = expr
```

This effectively creates a **full copy** of the `expr`'s Value. This means that for heap-stored types a new object containing the copy of the `expr`'s Value is created.  
Copy assignment is evaluated **right-to-left**.  

### Move Assignment

```{.numberLines}
dest_expr <- expr
```

Creates a temporary **partial copy** of `expr`, removes it from the data table (if `expr` is an idfr) and assigns the **partial copy** to `dest_idfr`.  
Move assignment is evaluated **left-to-right**.  

### Type-keeping Assignment

```{.numberLines}
dest_expr := expr
```

Evaluates `expr` and converts it to the `dest_expr`'s type before assigning to it.  
Type-keeping assignment is evaluated **right-to-left**.  

## Input / Output Operators

### Input Operator

```{.numberLines}
%> expr
```

Gets a value from stdin, deduces its type and assigns it to the specified variable / reference.  

Input can also be read as a String using `read_line([String prompt])` function.  

### Output Operators

* `%% expr` -- convert `expr`'s evaluation result to string and print it out to stdout.
* `<% expr`  -- print with a trailing newline.  

## Arithmetic Operators

If at least one operand of the expression is **Float**, the result is promoted to **Float** (except for bitwise operators and `%` -- only **Integer**s are supported, no implicit conversion is performed).  

**Binary:**  
`+`, `-`, `*`, `/`, `%`  
`+=`, `-=`, `*=`, `/=`, `%=`  
`&`, `|`, `^`, `>>`, `<<`  
`&=`, `|=`, `^=`, `>>=`, `<<=`  
\
**Unary:**  
`++`, `--` (both prefix and postfix)  
`-`, `~` (prefix)  

## String Operators

* `::` -- concatenation operator, converts operands to String and creates a new String with the result of concatenation.  
Example: `result = "One " :: 2 :: " " :: 3.0`.  

* `$$` (prefix) -- string conversion operator. Example:  

  ```{.numberLines}
  x = 123
  <% ($$x).substr(1)
  /* Outputs "23" */
  ```

## String Formatter

String formatter can be used in one of two ways:  

* Via a formatted string expression: `$"format" arg1, arg2, ...`
* Via a call to the `String@format()` method: `format_str.format(arg1, arg2, ...)`

Formatter syntax:  

* `{}`  is replaced by the next argument in list
* `{n}`, (`n` is an Int) is replaced by the `n`-th argument. Numbering starts with 1.

Each format cell `{...}` can contain the following modifiers:  

0. None at all (this will just be replaced by the next argument from the argument list).
0.5. Argument index (optional): `n`. Must be specified before any other modifiers.  

Other modifiers can be used in no particular order.  

1. Preferred width: `%n`.  
2. Alignment (left by default): `-l` for left / `-r` for right / `-c` for center.  
3. Floating point precision: `.n`.  

## Comparison Operators

`==`, `!=`, `>`, `>=`, `<`, `<=`  

Equals operator `==` works for every type (including Units -- in their case expression lists are compared), while all others are implemented only for numeric types.  

## Logical Operators

Binary:  
`&&`, `||`, `^^`  
\
Unary:  
`!`  

## Return Operator

Return operator stops the execution of a **Unit** and returns the result of the provided expression's evaluation.  

**Prefix:**  

* `return: expr` -- return by **partial copy** (copies only the pointer for heap-stored types, "full" copy can then be made via the `=` operator).

**Postfix:**  

* `expr!` -- return by **partial copy**.  

## Reference Operator

Get a reference to the **Value** associated with identifier:  
`**idfr`

Example:  

```{.numberLines}
foo = 123
ref = **foo
/* Now <foo> and <ref> point at the same Value */

%% ++ref	<-- Outputs 124
```

\
**Note:** To assign a reference to a variable it's always required to use the `**` operator before the expression being assigned, even if it evaluates to a reference. Otherwise, a copy of the value behind the reference will be assigned. Example:  

```{.numberLines}
f = func: x -> x *= 10 /* Explicit `**` is required only when assigning  */
foo = 123

bar = f(**foo)
/* `bar` is now an Int variable = 1230
 * (f() call evaluated to a copy instead of reference),
 * `foo` is now = 1230 */

baz = **f(**foo)
/* `baz` is now a Reference to `foo` = 12300,
 * so any subsequent changes to `baz` will modify
 * the value of `foo` */
```

## Reference-related Operators

* `unwrap: idfr` -- unwraps a named reference, e.g. `x = **y; unwrap: x` -- `x` becomes a copy of `y` instead of the reference to its value. Returns a reference to the unwrapped identifier.
* `is_reference: expr` -- returns true if `expr` evaluates to a Reference
* `expr!!` -- returns a copy of the value behind the reference `expr`

## Conditional (Ternary) Operator

`condition ? expr_then : expr_else`  

The condition is converted to Boolean and if true, the **Then** expression is evaluated and returned; otherwise -- the **Else** expression result is returned.  

## Range Expression

```{.numberLines}
start..end[..step]
```

Evaluates to a `Range` object (an `IntRange` or a `FloatRange` depending on `start`, `end` and `step` value types) that implements the `Iterable` interface. Ranges are end-exclusive.  
Can be used for:  

* Short form for loops:  `(1..10)[do: f: n -> foo(n)]`  
* Container slicing: `list[start..end]` -- evaluates to a new sublist with elements `start` to `end` exclusively  

# If-Else Expression

If-else expression in **Methan0l** uses the same syntax as ternary operator, but with `if` and `else` keywords used before the conditions and in between the **then** and **else** branches:

```{.numberLines}
/* if-else */
if (condition) ? {
	expr1
	...
} else: {
	else_expr1
	...
}

/* if only */
if (condition) ? {
	expr1
	...
}

/* if-elseif-...-else */
if (condition1) ? {
	expr1
	...
} else: if (condition2) ? {
	elseif_expr1
	...
} else: {
	else_expr1
	...
}

```  

# Loops

There are 3 types of loops in Methan0l. As with any other block expression, braces can be omitted for single expression loops.  

## For Loop

```{.numberLines}
for (i = 0, i < 10, ++i) {
	...
}
```

## While Loop

```{.numberLines}
while (i < 10) {
	...
	++i
}
```

## For-each Loop

Allows to iterate over any object, which class implements `Iterable`.  

```{.numberLines}
for (as_elem, iterable) {
	...
}
```  

## Break Expression

You can interrupt a loop via the break expression:  

```{.numberLines}
return: break
```

# Try-catch Expression

During a program's execution exceptions may be thrown either by the interpreter itself or native modules or by using the `die(expr)` function, where `expr` can be of any type and can be caught inside of a try-catch expression:

```{.numberLines}
try {
	...
} catch: name {
	...
}
```

# Units

There are 2 types of units: **regular** and **weak**.  The difference between them lies in scope visibility and execution termination rules.  

## Regular Units

**Regular** unit is a strongly scoped block of expressions (see [visibility scopes](#visibility-scopes) section).  
When a return expression is executed, regular unit stops its execution and yields the value being returned as its evaluation result.  

Function bodies are **regular** units.  

**Regular** units can be defined using the following syntax:  

```{.numberLines}
unit = {
	expr
	expr
	...
}
```

If assigned to an identifier, a unit then can be called either using identifier expression's execution syntax (returned value will be discarded in this case):  

```{.numberLines}
unit	/* <-- calls the unit defined above */
```

or using the function invocation syntax:  

```{.numberLines}
result = unit() /* <-- unit's return will be captured, if exists */
```  

## Weak Units

**Weak** units are weakly-scoped expression blocks and can access identifiers from the scopes above the current one up to the first **regular** unit without using the **#** prefix or importing references.  

Return from a **weak** unit also causes all subsequent **weak** units stop their execution and carry the returned value up to the first **regular** unit, causing it stop its execution and yield the carried value as its return value.  

Loops, if-else expressions and lambdas are **weak** units.  

Weak unit definition syntax:  

```{.numberLines}
-> {
	expr1
	expr2
	...
}
```

## Box Units

**Box unit** preserves its data table after the execution and is executed automatically on definition. Fields inside it can then be accessed by using the `.` operator.  

Modules loaded via the `load(path)` function or the `import: path` operator are **box units**.

Box unit definition syntax:  

```{.numberLines}
module = box {
	some_field = "Blah blah blah"
	foo = func @(x) {
		x.pow(2)!
	}
}

<% module.foo(5)	/* Prints 25 */
<% module.some_field	/* Prints contents of the field */
```  

\
Any non-persistent unit can also be converted to **box** unit using `make_box(Unit)` function.  

**Box** units as well as non-persistent ones can also be imported into the current scope:  

```{.numberLines}
module.import()
```

This effectively executes all expressions of `module` in the current scope.  


## Pseudo-function Invocation

**Units** can also be invoked with a single `Unit` argument (**Init Block**). **Init block** will be executed before the **Unit** being invoked and the resulting data table (which stores all identifiers local to unit) will be shared between them.  

This syntax can be used to "inject" identifiers into a unit when calling it, for example:  

```{.numberLines}
ratio = {
	if (b == 0) ? "inf"!
	return: (a / b) * 100.0
}

<% "a is " :: ratio({a = 3; b = 10}) :: "% of b"
```

# Functions

Functions accept a list of values and return some value (or **nil** when no return occurs).  

## Function Definition Syntax

```{.numberLines}
foo = func (arg1, arg2, arg3 => def_value, ...) {
    ...
}
```  

\
Or:
```{.numberLines}
foo = func: arg1, arg2, arg3 => def_value, ... {
    ...
}
```

\
If function's body contains only one expression, `{` & `}` braces can be omitted:  

```{.numberLines}
foo = func: x
	do_stuff(x)
```


## Implicit Return Short Form

```{.numberLines}
foo = func: x, y -> x + y
```

Here the expression after the `->` token is wrapped in a `return` expression, so its result will be returned from the function without needing to explicitly use the `return` operator.

## Multi-expression Short Form 

In this case no return expression is generated automatically.  

```{.numberLines}
bar = func: () -> a = 123, b = 456, out = a * b, out!
```

## Lambdas

Can be defined by using `@:` or `f:` function prefix instead of `func:`:  

```{.numberLines}
foo = @: x
	do_stuff(x)
```

Or:  

```{.numberLines}
foo = f: x
	return: x.pow(2)
```

Lambdas can also be used with implicit return and multi-expression short form of function body definition. However, they can't use the parenthesized argument definition form (only when a lambda accepts no arguments: `foo = f: () -> do_something()`).  

The key difference between lambdas and regular functions is that lambdas' bodies are **weak units**, which means that it's possible to access variables from their parent scopes without using global access syntax:  

```{.numberLines}
glob = "foo bar"
lambda = @: x
	glob[] = x

lambda(" baz") /* Appends " baz" to the global variable `glob` */
```

## Documenting Functions

When documenting Methan0l functions or methods, the following notation style should be used:  

### Return type

* Specify return type with `->` token:  
  `function() -> ReturnType`  

* If function can return any value, use `Value` after `->`.  

* If function doesn't have a return value, `->` can be omitted:  
  `non_returning_function()`

### Argument List

* Specify arguments of any type:  
  `function(a, b, c)`  

* Specify argument types:  
  `function(Int a, Boolean b)`  

* Specify arguments with default values:  
  `function(a, [String b = "default"])`

### Inherited Methods

When documenting methods inherited from a superclass or provided by an interface, use the following notation:

`superclass_method(arg) -> Class` *@ SuperClass*  

## Calling Functions

Functions can be called using **invocation syntax**:  

```{.numberLines}
result = foo(expr1, expr2, ...)
```

\
Functions can also be called by using **pseudo-method** syntax when the first argument is a built-in non-class type:  
```{.numberLines}
value.func(arg1, arg2, ...)
```

The expression above is internally rewritten as `func(value, arg1, arg2, ...)` when `value` is a primitive type, for example:  

```{.numberLines}
42.sqrt()
```

# Unevaluated Expressions

Can be created by using the following syntax:  

```{.numberLines}
foo = noeval: expr
```

In this case `expr` won't be evaluated until the evaluation of `foo`. When `foo` gets evaluated or executed, a new temporary value containing `expr`'s evaluation result is created and used in place of `foo` while `foo`'s contents remain unevaluated.  

Example:  
```{.numberLines}
x = noeval: y * 2
y = 2

/* Equivalent to x = 2 + 2 * 2 */
<% "Result: " :: (x += y)
```

<br>

# Classes

Even though Methan0l is not a pure OOP language, it supports classes with inheritance, interfaces and operator overloading.  

Class definition syntax:  

```{.numberLines}
class: ClassName {
	...
}
```

Class member (field, method, static method) definition follows the key-value syntax:  

```{.numberLines}
member => ...
```

## Fields

Fields can be initialized via the syntax mentioned above or defined just by mentioning their name in the class body:  

```{.numberLines}
class: ClassName {
	field1, field2
	field3 => 123
}
```

## Methods

Methods can be defined using the function definition syntax, but with `method` keyword instead of `func`:  

```{.numberLines}
class: ClassName {
	...

	foo => method: arg1, arg2 {
		<% "ClassName@foo()"
		this.field1 = arg1
		this.field2 = arg2
	}
}
```

Methods or fields of an object can be accessed by using the `.` operator:  
```{.numberLines}
foo = obj.field
obj.some_method(arg1, arg2, ...)
```  

Methods can also be static. Static methods are independent from any particular object and can be called on the class itself using the `@` token instead of `.` (e.g. `ClassName@static_method(...)`):  

```{.numberLines}
class: ClassName {
	...

	static_method => func: x {
		<% $"Static method arg: {}" x
	}
}
```

To distinguish static methods from non-static ones, the `func` keyword can be used instead of `method` when defining them.  

## Constructor

Constructors are defined by defining a special method named `construct`.  

Each class can only have one constructor.  

Contructor definition syntax:  

```{.numberLines}
class: ClassName {
	...

	construct => method: arg1, arg2, arg3 {
		this.field1 = arg1 + arg2 + arg3
		this.field2 = "stuff"
	}
}
```

Object construction syntax:  

```{.numberLines}
obj = new: ClassName(arg1, arg2, arg3)
```  

## Inheritance

Methan0l classes can only inherit from one superclass at a time and implement multiple interfaces.  

Constructor is inherited along with all other superclass methods.

Inheritance syntax:  

```{.numberLines}
class: Derived base: ClassName {
	...
}
```  

### Method Overriding

To override a superclass method, just re-define it. The parent version of the method can be called using the static invocation syntax with `this` reference passed explicitly:  

```{.numberLines}
class: Derived base: ClassName {
	...

	foo => method: arg1, arg2 {
		ClassName@method(this, arg1, arg2)
		<% "Derived@foo()"
	}
}
```

## Operator Overloading

To overload an operator, specify its name as a string literal and then define it as a method:  

```{.numberLines}
class: Foo {
	...
	
	"+" => method: rhs {
		return: new: Foo()
	}

	"*=" => method: rhs {
		<% "Overloaded compound assignment"
		return: this
	}
}
```

## Index Operator Overloading

All of index operator subtypes can be overloaded for user-defined classes. Overload names should be quoted.  

* Get an element: `container[expr]`. Overload as: `"[]" => method: idx {...}`.  
* Append an element: `container[] = expr`. Overload as: `"append[]" => method: () {...}`.  
* Remove element: `container[~expr]`. Overload as: `"remove[]" => method: idx {...}`.  
* Clear: `container[~]`. Overload as: `"clear[]" => method: () {...}`.  
* Iterate over a container: `container[do: Function]`. Overload as: `"foreach[]" => method: action {...}`.  
* Insert into a container: `container[->expr]`. Overload as: `"insert[]" => method: elem {...}`.  
* Slice a container: `container[start..end[..step]]`. Overload as: `"slice[]" => method: range {...}`.  

## Copying Objects

Objects can be copied using `copy: obj` operator.  

## Anonymous Objects

Methan0l supports anonymous objects which can be used to pass around multiple named values.  

Anonymous objects can also work as prototypes: when used in the RHS of the `new` operator, a deep copy of the object is created and then its constructor (if defined) is invoked (e.g. `new_anon_obj = new: anon_obj(123)`, where `anon_obj` is an anonymous object with defined constructor).  
Methods defined inside anonymous objects (including constructor) must have an explicit `this` argument in their parameter list.  
Generally, defining methods inside such objects is a huge overhead as they are stored inside the object's data table and are copied along with new objects when used inside of `new` or `copy` operator.  

Example of anonymous object usage:  

```{.numberLines}
{
	obj = new: @[
		x => 123
		y => "some text"

		some_func => func: x
			return: x * 10

		foo => method: this, n
			return: this.x * n
	]

	<% "obj.x = " :: obj.x
	<% "Anonymous object method call: " :: obj.foo(2)

	/* For now there's no other way to do this */
	<% "Regular function: " :: obj.get_method("some_func")(42)
}
```

Output:  

```{.numberLines}
obj.x = 123
Anonymous object method call: 246
Regular function: 420
```

## Reflection

Get class's unique id: `class_id()`. Can be invoked as a static method or as a method of an object:  

```{.numberLines}
obj = Class.new(a, b, c)
obj.class_id() == Class@class_id()
/* ^^ Evaluates to true ^^ */
```

Get all fields / methods of a class:  

```{.numberLines}
Class@get_fields() -> List
Class@get_methods() -> List
```

These methods return lists of class' field / method names.  
Specific fields can then be accessed from this class' instance by name using the `Class@get_field(name) -> Value` method, e.g:  

```{.numberLines}
obj = new: SomeClass(42)
fields = SomeClass@get_fields()
<% $"Some field of `obj`: {}" obj.get_field(fields[0])
```

Specific methods can be invoked by name via the `Class@get_method(name)` static method:  

```{.numberLines}
methods = SomeClass@get_methods()
SomeClass@get_method(methods[0])(obj, arg1, arg2)
```

# Path Prefixes

The following special prefixes can be used at the beginning of path strings everywhere in Methan0l:  

* `$:` - expands into interpreter home directory.  
* `#:` - expands into script run directory.  

For example: `"$:/modules/ncurses"` becomes: `"/opt/methan0l/modules/ncurses"`.  

# Built-in Interfaces

## Iterable

Interface `Iterable` requires classes implementing it to define a single method `iterator()`, which should return an object implementing the `Iterator` interface.  
`Iterable` also provides a number of useful transformation methods:  

* `map(Function) -> Iterable` - map an `Iterable` into another `Iterable` by applying a function to it. This yields an `Iterable` and doesn't produce any containers or other "heavy" objects as a result.  
* `filter(Function) -> Iterable` - create an `Iterable` that discards all elements from the original `Iterable` that don't satisfy a predicate.
* `for_each(Function)` - perform an action for each element of an `Iterable`.  
* `accumulate(Function) -> Value` - apply a two-argument function (where the first argument is the value accumulated so far and the second one is an element from an `Iterable`) and return the accumulated result.  
* `collect(Collection) -> Collection` - insert all values from an `Iterable` into a `Collection` and return it.  

`Iterable` also provides some built-in accumulative methods (specializations of `Iterable@map(Function)`):  

* `sum() -> Float`  
* `product() -> Float`  
* `mean() -> Float`  
* `rms() -> Float` - root mean squared.  
* `deviation() -> Float` - standard deviation.  

## Iterator

This interface describes an abstract iterator to be returned by the `Iterable@iterator()` method.  

Methods:  

* `peek() -> Value` -- should return the element the iterator is currently pointing at.
* `next() -> Value` -- should return the current element and advance the iterator one element forward.
* `has_next() -> Boolean` -- should return whether there is an element after the current one.  
* `skip([Int n = 1]) -> Value` -- should skip `n` elements and return the element iterator is pointing at after the skip.  
* `can_skip([Int n = 1]) -> Boolean` -- should return whether the iterator can skip `n` elements forward.  
* `reverse()` -- if the iterator is at the beginning of the sequence, this method should set current element to the last one, otherwise, if the iterator is at the end of the sequence, it should be moved to its beginning.  
* `previous() -> Value` -- should return the previous element.  
* `has_previous() -> Boolean` -- should return whether there is a previous element.  
* `remove() -> Value` -- should remove the current element of the iterator.  

## Collection

**Inherits**: `Iterable`  

This interface describes a collection of elements, such as a list or a set.  

Methods:

* `add(element) -> Value` -- should add an element to the collection.  
* `append() -> Value` -- should add a `nil` element to the collection and return a reference to it.  
* `remove(element) -> Value` -- should remove the specified element from the collection.
* `remove_at(Int idx) -> Value` -- should find the specified element and remove it from the collection.  
* `get(Int idx) -> Value` -- should return a reference to the element at the specified index.  
* `size() -> Int` -- should return the collection's element count.  
* `resize(Int idx)` -- should grow / truncate the collection.  
* `clear()` -- should remove all elements from the collection.  
* `is_empty() -> Boolean` -- should return whether the collection is empty.  
* `index_of(element) -> Int` -- should find the specified element and return its index.  
* `contains(element) -> Boolean` -- should return whether the collection contains the specified element.  
* `iterator() -> Iterator` *@ Iterable* -- should produce an `Iterator` for the collection.  

`Collection` also provides the following methods:  

* `fill(Value elem, [Int size = 0]) -> Collection` -- fills the collection with specified element. If `size` is specified, the collection is resized before the filling operation.  
* `add_all(Collection other) -> Collection` -- adds all elements from `other` to this collection.  
* `remove_all(Collection other) -> Collection` -- removes all elements that are present in `other` from this collection.  
* `retain_all(Collection other) -> Collection` -- removes all elements that are not present in `other` from this collection.  

Operator overloads:  

* `Collection += Value` -- appends RHS to the collection via the `add(Value)` method.  
* `Collection -= Value` -- removes RHS from the collection using the `remove(Value)` method.  

## AbstractMap

**Inherits**: `Iterable`  

This interface describes an abstract key-value container.  

Methods:  

* `add(key, value) -> Value` -- should add a `key` - `value` pair to the map and return the value previously associated with the `key` (if any).  
* `remove(key) -> Value` -- should remove and return a value assocciated with the `key`.  
* `get(key) -> Value` -- should return the value associated with the `key`.  
* `contains_key(key) -> Boolean` -- should return whether the map contains the specified key.  
* `size() -> Int` -- should return the map's entry count.  
* `clear()` -- should remove all entries from the map.  
* `is_empty() -> Boolean` -- should return whether the map is empty.  
* `iterator() -> Iterator` *@ Iterable* -- should produce an `Iterator` for the map.  

### MapEntry

A special utility interface designed to be used for iterating over maps.  

Methods:  

* `key() -> Value` -- should return the entry's key.
* `value() -> Value` -- should return the entry's value.

## Range

**Implements**: `Iterable`  

This interface describes an abstract range in form `[start, start + step, start + step * 2, ..., end]`.  

Methods:

* `get_start() -> Value`
* `get_end() -> Value`
* `get_step() -> Value`

# Built-in Classes {.unnumbered}

# Container Classes

## Pair

Represents a pair of values.  

Constructor:  

```{.numberLines}
new: Pair(a, b)
```

Methods:  

* `swap(b)` -- swaps the contents of this pair with the pair `b`.  

* `x() -> Value`, `y() -> Value` -- first and second element getters (by reference).  

* `swap_contents()` -- swaps first and second elements.  

## List

**Implements**: `Collection`  

List definition syntax:  

```{.numberLines}
list = [expr, expr, expr, ...]
```

Methods:  

* `add(element) -> Value` -- add an element to the end of this list.
* `append() -> Value` -- creates a `nil` value at the end of this list and returns a reference to it.
* `remove(element) -> Int` -- searches for the supplied element and removes it from the list. Returns the index of the deleted element.  
* `remove_at(Int idx) -> Value` -- removes an element by index. Returns the deleted element.  
* `get(Int idx) -> Value` -- returns a reference to the element at supplied index.  
* `size() -> Int` -- returns the size of the list.  
* `resize(Int new_size)` -- resizes the list to specified size. If `new_size` is greater than `size()`, `new_size - size()` new `nil` elements will be created and appended to the list. If `new_size` is less than `size()`, list will be truncated.  
* `clear()` -- clears the list.  
* `is_empty() -> Boolean` -- returns `true` if  `size()` is equal to 0.
* `index_of(element) -> Int` -- searches for specified element and returns its index.  
* `contains(element) -> Boolean` -- returns `true` if the list contains specified element.  
* `iterator() -> ListIterator` -- produces an `Iterator` that iterates through all elements of the list.  

Operator overloads:  

* `list[Int] -> Value` -- get an element by index.  
* `list[] = expr` -- append an element.  
* `list[~Int] -> Value` -- remove an element by index.  
* `list[~] -> List` -- clear the list.  
* `list[do: Function] -> List` -- iterate over the list.  
* `list[start..end[..step]] -> List` -- produce a sublist of this list with elements at indices in specified range.  

## Set

**Implements**: `Collection`

Set definition syntax:  

```{.numberLines}
set = new: Set(List)
```  

Methods:  

* `add(element) -> Value` -- add the `element` to this set. Returns `true` if the `element` wasn't present in the set before calling this method.  
* `remove(element) -> Boolean` -- removes the `element` from this set. Returns whether this element was present in the set.  
* `size() -> Int` -- returns the size of the set.  
* `clear()` -- clears the set.  
* `is_empty() -> Boolean` -- returns `true` if  `size()` is equal to 0.
* `index_of(element) -> Int` -- searches for specified element and returns its index.  
* `contains(element) -> Boolean` -- returns `true` if the set contains specified element.  
* `iterator() -> SetIterator` -- produces an `Iterator` that iterates through all elements of the set.  
* `a.union(b) -> Set` -- produces a new `Set` that contains the union of this set and set `b`.  
* `a.intersect(b) -> Set` -- produces a new `Set` that contains the intersection of this set and set `b`.  
* `a.diff(b) -> Set` -- produces a new `Set` that contains the difference of this set and set `b`.  
* Symmetric difference: `a.symdiff(b)` -- produces a new `Set` that contains the symmetric difference of this set and set `b`.  

Operator overloads:  

* `set[->expr] -> Boolean` -- insert an element into this set.  
* `set[Value] -> Boolean` -- test if an element is present in the set.  
* `set[~Value] -> Boolean` -- remove an element from the set.  
* `set[~] -> Set` -- clear the list.  
* `set[do: Function] -> Set` -- iterate over the set.  
* `set[start..end[..step]] -> Set` -- produce a subset of this set with elements at indices in specified range.  

## String

**Implements**: `Collection`

String definition syntax:  

```{.numberLines}
str = "some text"
str = new: String()
str = new: String(other_string)
```

Methods:  

* `format(Value args...) -> String` -- produce a new string formatted using the string formatter according to this string and supplied arguments.  

* `substr(start, [length]) -> String`  -- returns a substring of the specified string, starting from the `start`'th character. If length is not specified, the remainder is used.

* `find(substr, [start_pos]) -> Int` -- returns index of `substr` inside the specified string. If not found, `-1` is returned instead.

* `contains(substr) -> Boolean` -- returns `true` if specified string contains `substr` at least once.

* `split(delim_expr) -> List` -- returns a **List** of tokens.

* `repeat(Int times)` -- produce a new string containing this string repeated `times` times.  

* `erase(Int start, [Int length])` -- erases a substring from the specified string, starting from the `start`'th character. If length is not specified, the remainder is used.

* `replace(from_str, to_str, [limit])` -- replace `limit` occurrences of `from_str` with `to_str`. If limit is not specified, all occurrences will be replaced.

* `insert(pos, substr)` -- insert `substr` after the `pos`'th character of the provided string.  

* `append(String)` -- appends a string to this string.  

* `concat(String other)` -- produces a new string containing this string and `other` joined together.  

* `add(String) -> String` -- appends a string / character to this string.  

* `remove(Character) -> Int` -- searches for the first occurrence of the supplied character and removes it from the string. Returns the index of the deleted character.  

* `remove_at(Int idx) -> Character` -- removes a character by index. Returns the deleted character.  

* `get(Int idx) -> Character` -- returns a character at supplied index.  

* `size() -> Int` -- returns the size of the string.  

* `resize(Int new_size)` -- resizes the string to specified size. If `new_size` is greater than `size()`, `new_size - size()` new null characters will be created and appended to the string. If `new_size` is less than `size()`, string will be truncated.  

* `clear()` -- clears the string.  

* `is_empty() -> Boolean` -- returns `true` if  `size()` is equal to 0.

* `index_of(Character) -> Int` -- searches for the first occurrence of specified character and returns its index.  

* `contains(Character) -> Boolean` -- returns `true` if the string contains specified character.  

* `iterator() -> StringIterator` -- produces an `Iterator` that iterates through all characters of the string.  

Operator overloads:  

* `string[Int] -> Value` -- get a character by index.  
* `string[] = expr` -- append a string / character.  
* `string[~Int] -> Value` -- remove a character by index.  
* `string[~] -> List` -- clear the string.  
* `string[do: Function] -> List` -- iterate over the string.  
* `string[start..end[..step]] -> List` -- produce a substring of this string with characters at indices in specified range.  

## Map

**Implements**: `AbstractMap`

Map definition syntax:  

```{.numberLines}
map = @[
	key1 => val1
	key2 => val2
	...
]
```  

Or:

```{.numberLines}
map = new: Map()
```

Methods:  

Implements all methods declared by the [AbstractMap](#abstractmap) interface along with:  

* `iterator() -> MapIterator` -- produces an `Iterator` that iterates through all key-value pairs of this map represented by `MapEntry` objects.  
  So, to iterate over a map, you can do somethig like this:  

  ```{.numberLines}
  for (entry, map) {
  	key = entry.key()
  	value = entry.value()
  	...
  }
  ```  

Operator overloads:  

* `map[key]` -- access an existing / add new value by key.  
* `map[~key]` -- remove an entry by key.  
* `map[~] -> Map` -- clear the map.  
* `map[do: Function] -> Map` -- iterate over the map.  

# Iterable Classes

## Mapping

A class of objects produced by the `Iterable@map(Function) -> Mapping` method.  
Maps an `Iterable` into another `Iterable` by applying the supplied function to it.  

Methods:  

* `iterator() -> MappingIterator` -- produces an `Iterator` that applies the supplied function to each element of the `Iterable` being mapped.  

## Filter

A class of objects produced by the `Iterable@filter(Function) -> Filter` method.  
Maps an `Iterable` into another `Iterable` by discarding elements that do not satisfy the supplied predicate.  

Methods:  

* `iterator() -> FilterIterator` -- produces an `Iterator` that applies the supplied predicate to each element of the `Iterable` being mapped and discards all elements for which its value is `false`.  

## IntRange / FloatRange

A class of objects produced by the range built-in function and the range expression.  
Represents an arbitrary numeric sequence.  

Methods:  

* `iterator() -> RangeIterator` *@ Iterable* -- produces an `Iterator` that iterates through every number in sequence.  

* `get_start() -> Int / Float` -- returns the `start` value of this `Range`.

* `get_end() -> Int / Float` -- returns the `end` value of this `Range`.  

* `get_step() -> Int / Float` -- returns the `step` value of this `Range`.  

<br>

# Utility Classes

## File

Constructor:  

```{.numberLines}
file = new: File(path_str)
```  

Methods: 

Read / Write Operations:  

* `open()` -- open file for reading / writing.  

* `close()` -- close file.  

* `read_line() -> String` -- read one line from file as string.  
Sets `eof()` property to **true** if the end of file has been reached.  

* `write_line(line)` -- write a string to file.  

* `read_contents() -> String` -- returns full contents of the managed file as string.  
Doesn't require the file to be `open()`'d.

* `write_contents(str)` -- writes the whole string `str` to file, deleting previous contents, if any.  
Doesn't require the file to be `open()`'d.

Miscellaneous:  

* `set(path)` -- sets the path of the file managed by this object.

* `mkdirs()` -- creates all non-existing directories in the managed path.

* `cd()` -- changes current working directory to the managed path.

* `equivalent(path) -> Boolean` -- returns `true` if managed file path is equivalent to the specified path.  

* `copy_to(path)` -- copies managed file to the specified path.  

* `extension() -> Boolean` -- returns the file's extension.  

* `size() -> Int` -- returns file size in bytes.  

* `absolute_path() -> String` -- returns absolute path to the managed file.  

* `filename() -> String` -- returns filename of the managed file.

* `is_dir() -> Boolean` -- returns `true` if this file is a directory.  

* `exists() -> Boolean` -- returns `true` if this file exists.  

* `for_each(Function action)` -- iterates recursively through all files in directory described by the managed path, calling `action(file_name)` for each one of them.  

* `rename(new_name)` -- renames managed file.  

* `remove()` -- removes managed file from disk.  

Static Methods:  

* `cwd() -> String` -- returns path to the current working directory.  

Properties: 

* `eof() -> Boolean` -- is set only after calling read operations. **True** if the end of the managed file has been reached.  

\
! All **File** methods (that don't modify the state of the object) can be invoked statically by specifying the path for invoked operation as the first argument, for example:  

```{.numberLines}
File@exists("./foo/bar.txt")
```


## Random

Constructor:  

```{.numberLines}
rnd = new: Random([Int seed])
```  

If `seed` is not specified, a random one will be used.  

Methods:  

RNG Seeding:  

* `get_seed() -> Int` -- returns seed used by this rng.

* `reseed(Int new_seed)` -- re-seeds the rng with specified seed.

Random Integer:  

* `next_int([Int n]) -> Int` -- returns next pseudo-random 64-bit integer. If `n` is specified, generated value will be in range **[0; n)**.  

* `next_int(Int a, Int b) -> Int` -- returns next pseudo-random integer in range **[a; b]**.  

Random Float:  

* `next_double([Float n]) -> Float` -- if `n` is not specified, returns next pseudo-random float in range **[0; 1]**. Otherwise, generated value will be in range **[0; n)**.  

* `next_double(Float a, Float b) -> Float` -- returns next pseudo-random float in range **[a; b - 1]**.  

Random Boolean:  

* `next_boolean([Float probability = 0.5]) -> Boolean` -- returns `true` with probability `probability` in range **[0; 1]**.  

<br>

# Modules

## Module API (Legacy)

The current module architecture is deprecated.  

Modules should use the `Library` loading and initialization mechanism.  

Modules are just shared libraries that define a special function `void init_methan0l_module(mtl::ExprEvaluator*)` to be able to hook up to the interpreter instance.  
This function can be defined using the `INIT_MODULE` macro that is a part of the methan0l module API (defined in the `methan0l.h` header in the root source directory).  
Modules can optionally define an initialization function via the `LOAD_MODULE {...}` macro.  
Alternatively, functions can be bound to the interpreter even without the `LOAD_MODULE` entry point by using the `FUNCTION(name)` macro inside of the source file, where `name` is a name of an already declared function.  
C++ classes can also be bound to methan0l classes via the `NativeClass<...>` helper or directly using the `ClassBinder<...>` class.  

You can see an example of module API usage (including `ClassBinder`) in `modules/test`.  

## Loading Modules

Load a Methan0l source file or a native module as a Box Unit:  

```{.numberLines}
load(path_str_expr)
```

Loaded module can be assigned to a variable and its contents can be accessed via the `.` operator, as with regular Box Units:  

```{.numberLines}
sys = load("system")
<% sys.exec("ls -a")
```

Modules can also be imported into the current scope after loading:  

```{.numberLines}
sys = load("system")
sys.import()
```

Or imported in-place via the `import` operator:  

```{.numberLines}
import: "system"
import: "test"

<% sys.exec("ls -a")
test()
```

### Module Path Resolution

Module paths are resolved in the following steps:  

1. If supplied path exists
  * If this is a path to a file, the module path is resolved.
  * If this is a path to a directory, append its name to the supplied path and return to step 1.
2. If supplied path does not exist
  * Try to resolve it as a Methan0l script file by appending the `.mt0` extension.
  * Try to resolve it as a native shared library by appending the `.so` extension.
3. If supplied path is relative and does not exist
  * Try to resolve it relative to the `modules` directory located in the interpreter home directory by prepending home path to the supplied path and returning to step 1.

<br>

# Core Library {.unnumbered}

# Input / Output Operators & Functions `[LibIO]`

Input operator:  
`%> idfr`

String input function:  
`read_line([prompt])` -- read string from stdin and return it. The optional `prompt` argument will be converted to string and printed to the stdout before requesting user input, if supplied.  

Output operators:  
`<% expr` -- print with trailing newline character  
`%% expr` -- print without a trailing newline character  

<br>

# String-related Functions `[LibString]`

Radix conversion: 

`to_base(String, Int dest_base, [Int src_base = 10]) -> String` -- returns a string representation of the provided numeric string converted from base `src_base` to base `dest_base`. This function automatically converts its first argument to string, so numeric values can be passed to it too.  

<br>

# Data Structure Operators & Functions `[LibData]`

## Hashing Values of Any Type

```{.numberLines}
hash_code: expr
```  

Can be overloaded for classes via defining a `hash_code()` method.  

## Deleting Values

```{.numberLines}
delete: idfr
```

Delete the identifier from the data table (and the value associated with it if it's a primitive or a heap-stored value with refcount == 0 after identifier deletion).  

## Type Operators

* `typeid: expr` -- get **typeid** of value.  
Can be used for type-checking.

  Example:  

  ```{.numberLines}
  <% typeid: "foo" == type string /* Prints "true" */
  ```

* `msg_expr assert: condition_expr`

* `expr require: type_expr, type_expr2, ...`

* `expr is: type_expr`

## Type Conversion

```{.numberLines}
expr.convert(type_expr)

/* Or via an operator: */

expr to: type_expr
```

Here `type_expr` can be a type name, a string, or a numeric type id (that was obtained via a type reference expression or by invoking the `class_id()` method of an object).  
Converts the value of the expression on the left hand side to specified type, for example:  

```{.numberLines}
bool = "true".convert(Boolean)
str = 1337.convert(String)
dbl = "-1.234".convert(Double)
set = $(123, 234, 345).convert(Set)
```  
  
## Variadic Function Arguments

```{.numberLines}
args = get_args()
```

Can be called from inside a function's body to get a list of all arguments passed to it, including extra arguments not defined in the function's parameter list.

## Command Line Arguments
```{.numberLines}
get_launch_args()
```

Get command line args passed to the currently running Methan0l program.  

## Range

Create a `Range` iterable object (an `IntRange` or a `FloatRange` depending on argument types):  

Range **[0, n)**:  

```{.numberLines}
range(Int n) -> Range
```
\
Range **[start, n)**:  

```{.numberLines}
range(Int start, n) -> Range
```
\
Range **[start, start + step, ..., n)**:  

```{.numberLines}
range(Int start, Int n, Int step) -> Range
```  

<br>

# Internal Functions `[LibInternal]`

## Get Environment Info  

* `get_os_name() -> String`  

* `get_arch() -> String`  

* `get_rundir() -> String` -- get path to the working directory from which the interpreter (or a program that uses the interpreter in embedded setting) has been launched.  

* `get_runpath() -> String` -- same as previous function, but with binary name appended.  

* `get_home_dir() -> String` -- get path to the interpreter home directory.  

* `get_bin_path() -> String` -- get path to the binary using the interpreter.  

## Heap-related Functions

* `mem_in_use() -> Int`, `max_mem() -> Int` -- get current heap state.  

* `set_max_mem(Int)` -- set max heap capacity.  

* `mem_info()` -- print current heap state.  

* `enforce_mem_limit(Boolean)` -- toggle either to throw an exception when exceeding the max heap capacity or not.  

## Methan0l Version Info

* `get_version() -> String` -- returns version string  

* `get_version_code() -> Int` -- returns interpreter version code. Negative for unstable versions.  

* `get_minor_version() -> Int`  

* `get_release_version() -> Int`  

* `get_major_version() -> Int`  

## Unit-related Functions & Operators `[LibUnit]`

`sync_work_dir()` -- change working directory to the location of currently running script

## Persistence

`unit.make_box()` -- get a persistent copy of Unit (preserves Unit's data table after the execution)  

## Check if current Unit is the program's entry point

`is_main_unit()` -- true if unit currently being executed is at the bottom of the execution stack

## Execution Control

* `exit()` -- stop program execution.  

* `die(expr)` -- throw an exception `expr` that can be caught by a try-catch statement.

* `err(msg)` -- print `msg` to stderr.

* `pause(msecs)` -- pauses execution for at least `msecs` milliseconds.

* `selfinvoke(...)` -- can be used from inside a function's body to recursively call it.

* `unit.local(action)` -- execute `action` inside `unit`'s scope.  
If `unit` is **non-persistent**, it's executed first and `action` is executed after it. `unit`'s data table is then cleared as if after a regular execution.

## Benchmark

`measure_time(expr)` -- returns time spent on evaluation of `expr` in milliseconds, discarding the result, if any.

## Reflection

**Get a reference to identifier's value by name:**

* `unit.value("idfr_name")` or `unit["idfr_name"]` -- performs lookup in `unit`'s scope.

* `value("idfr_name")` -- global scope lookup.  

<br>

# Common Math Functions `[LibMath]`

## Trigonometry

* `rad(Float deg) -> Float` -- convert degrees to radians.  

* `deg(Float rad) -> Float` -- convert radians to degrees.  

* `sin(Float rad) -> Float`  

* `cos(Float rad) -> Float`  

* `tan(Float rad) -> Float`  

* `acos(Float x) -> Float`  

* `asin(Float x) -> Float`  

* `atan(Float x) -> Float`  

* `atan2(Float x, Float y) -> Float`  

## Power functions

* `pow(Float/Int x, Float/Int n) -> Float/Int`  

* `sqrt(Float x) -> Float`

## Exponential and Logarithmic Functions

* `exp(Float x) -> Float`  

* `log(Float x) -> Float`  

* `log10(Float x) -> Float`  

* `logn(Float base, Float x) -> Float`

## Rounding

* `ceil(Float x) -> Float`  

* `floor(Float x) -> Float`  

* `round(Float flt, Int n) -> Float` - round `flt` to `n` decimal places

## Absolute Value

* `abs(Float/Int x) -> Float/Int`

<br>

# Standard Modules {.unnumbered}

# System

```{.numberLines}
import: "system"
```

* `exec(str) -> Pair` -- execute `str` as a system shell command. Returns a pair of `{stdout_str, return_value}`.  

* `get_env(name) -> String` -- get value of a system environment variable.

# Ncurses

```{.numberLines}
import: "ncurses"
```

Partial libncurses bindings.  
