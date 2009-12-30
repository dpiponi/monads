\documentclass[preprint,onecolumn]{sigplanconf} 
\usepackage{amsmath} 
\usepackage{amssymb} 
\usepackage{graphicx} 
\usepackage{eepic}
\usepackage{tikz}
\newcommand{\cL}{{\cal L}} 
\newcommand{\2}{^{\underline{2}}}
\usetikzlibrary{shapes,arrows}

%include lhs2TeX.fmt
%include lhs2TeX.sty

%options ghci
%if False

--> import Prelude hiding (Monad(..))

%endif

\begin{document} 

\title{Monads}
\authorinfo{Dan Piponi}{}{dpiponi@@gmail.com}
\maketitle

\section{Why Another Tutorial?}


\section{Trees}
Haskell type classes are interfaces shared by different types and Haskell's |Monad| type class is no different. It describes an interface common to many types of tree structure, all of which share the notion of a {\em leaf node} and {\em grafting}. These are straightforward notions from computer science and are easily illustrated.

So let's start by looking at the type class definition:

< class Monad m where
<   return :: a -> m a
<   (>>=) :: m a -> (a -> m b) -> m b

Here |m| is a type constructor. Given a type |a| it constructs a new type |m a| with these two functions. We can make an instance of this class by defining a simple binary tree type:

> data Tree a = Fork (Tree a) (Tree a) | Leaf a | Nil deriving Show

|Tree| takes a type |a| and makes a new type from it |Tree a|. Elements of type |Tree a| are either forks with two subtrees, leaves containing a single element of type |a| or a empty trees called |Nil|.

Here's a typical expression representing a tree:

> tree1 = Fork (Fork (Leaf 2) Nil) (Fork (Leaf 2) (Leaf 3))

We can draw this in the standard way:

\begin{center}
\begin{tikzpicture}
\tikzstyle{level 1}=[sibling distance=2in]
\tikzstyle{level 2}=[sibling distance=1in]
\coordinate
    child {
        child {node {|Leaf 2|}}
        child {node {|Nil|}}
    }
    child {
        child {node {|Leaf 2|}}
        child {node {|Leaf 3|}}
    };
\end{tikzpicture}
\end{center}

To show how the monad interface works we can start defining a |Monad| instance for |Tree|:

> instance Monad Tree where
>   return a = Leaf a

The function |return|, despite the name, is nothing more than a function for creating leaf nodes. The next function is a grafting operation:

>   Nil      >>= f = Nil
>   Leaf a   >>= f = f a
>   Fork u v >>= f = Fork (u >>= f) (v >>= f)

The idea is that given a tree we'll replace every leaf node with a new subtree. We need a scheme to be able to specify what trees are grafting in to replace which leaves. One way to do this is like this: we'll use the value stored in the leaf to specify what tree to graft in its place, and we'll make the specification by giving a function mapping leaf values to trees. I'll illustrate it pictorially first, with a simple tree. Consider:

> tree2 = Fork (Leaf 2) (Leaf 3)

\begin{center}
\begin{tikzpicture}
\tikzstyle{level 1}=[sibling distance=2in]
\tikzstyle{level 2}=[sibling distance=1in]
\coordinate
    child {
        node {|Leaf 2|}
    }
    child {
        node {|Leaf 3|}
    };
\end{tikzpicture}
\end{center}

Now I want to graft these two trees into |tree2| so that the left one replaces |Leaf 2| and the right one replaces |Leaf 3|:
\begin{center}
\begin{tikzpicture}
\tikzstyle{level 1}=[sibling distance=2in]
\tikzstyle{level 2}=[sibling distance=1in]
\coordinate
    child {
        node {|Nil|}
    }
    child {
        node {|Leaf "Two"|}
    };
\end{tikzpicture}
\end{center}
\begin{center}
\begin{tikzpicture}
\tikzstyle{level 1}=[sibling distance=2in]
\tikzstyle{level 2}=[sibling distance=1in]
\coordinate
    child {
        node {|Leaf "Three"|}
    }
    child {
        node {|Leaf "String"|}
    };
\end{tikzpicture}
\end{center}

The result should be:
\begin{center}
\begin{tikzpicture}
\tikzstyle{level 1}=[sibling distance=2in]
\tikzstyle{level 2}=[sibling distance=1in]
\coordinate
    child {
        child {node {|Nil|}}
        child {node {|Leaf "Two"|}}
    }
    child {
        child {node {|Leaf "Three"|}}
        child {node {|Leaf "String"|}}
    };
\end{tikzpicture}
\end{center}

We carry this out by writing a function that maps |2| to the left tree and |3| to the right tree. Here's such a function:

> f 2 = Fork Nil (Leaf "Two")
> f 3 = Fork (Leaf "Three") (Leaf "String")

We can now graft our tree using:

> tree3 = tree2 >>= f

I hope you can see that the implementation of |>>=| does nothing more than recursively walk the tree looking for leaf nodes to graft.

All instances of |Monad| can be views as trees similar to this.

\section{Computations}
If this interface were merely for building tree structures it wouldn't be all that interesting. Where it starts to get useful is when we use trees to represent different ways to organise a computation. For example, consider the kind of combinatorial search involved in finding the best move in a game. Or consider decision-tree flowcharts or probability trees. Even simple ordered linear sequences of operations form a kind of degenerate tree without branching. The monad interface can be used with all of these structures giving a uniform way of working with them.

\section{Combinatorial Search}
Let's start by putting the |Tree| example above to work. Combinatorial search trees can quickly grow too large to fit on a page so I'm deliberately going to pick a particularly simple problem to solve so that every part of it can be laid bare.

Let S be the set $\{2,5\}$ and suppose we wish to find all of the possible ways we can form the sum of three numbers chosen from this set (with possible repeats). For example $2+5+2$ or $5+5+5$. We can break this problem down into three steps, picking a number at each stage. We can draw a diagram representing the possibilities as follows:

\begin{center}
\begin{tikzpicture}
\tikzstyle{level 1}=[sibling distance=2in]
\tikzstyle{level 2}=[sibling distance=1in]
\coordinate
    child {
        node {|Leaf 2|}
    }
    child {
        node {|Leaf 5|}
    };
\end{tikzpicture}
\end{center}

The Haskell code is:

> tree4 = Fork (return 2) (return 5)

Now we wish to construct the tree for the next stage. We want to replace the left node with a subtree that represents the two possibilities we might get given that we picked $2$ at the first stage. Similarly we want to replace the right leaf with the possibilities that start with $5$. In other words, we want to replace |Leaf n| with the tree

\begin{center}
\begin{tikzpicture}
\tikzstyle{level 1}=[sibling distance=2in]
\tikzstyle{level 2}=[sibling distance=1in]
\coordinate
    child {
        node {|Leaf (n+2)|}
    }
    child {
        node {|Leaf (n+5)|}
    };
\end{tikzpicture}
\end{center}

In other words, we want to graft with the function

> choose n = Fork (Leaf (n+2)) (Leaf (n+5))

Our two stage tree is given by

> stage2 = tree4 >>= choose

Now we want to replace each of these leaf nodes with a new subtree. We can reuse our rule to get

> stage3 = stage2 >>= choose

If you run the code you'll see that |stage3| has all of the possibilities stored in the tree and we have solved our problem.

We can reorganise this code a little. A helper |fork| function saves on typing:

> fork a b = Fork (Leaf a) (Leaf b)

I've implemented |choose| as a separate function but we could write out everything longhand as follows:

> stage3' = (fork 2 5 >>= \a ->
>            fork (a+2) (a+5)) >>= \b ->
>            fork (b+2) (b+5)

I've simply substituted lambda terms for the function choose. We can now see the three stages clearly as one line after another. We can read this code from top to bottom as a sequence of three operations interpreting the |fork| function as something like the Unix |fork| function. After a fork, the remainder of the lines of code are executed {\em twice}, each time using a different value. Writing it out fully makes it clear that we can easily change the choice at each line,

An important thing to notice about our three stage tree is that there were two ways of building it. I first built a two stage tree and then grafted a one stage tree into each of its leaves. But I could have built a one stage tree and substituted a two stage tree into each of its leaves. We can see this diagrammatically as:

Our alternative code looks like this:

> stage3'' = fork 2 5 >>= \a ->
>            fork (a+2) (a+5) >>= \b ->
>            fork (b+2) (b+5)

It's almost the same, I just removed parentheses.

We can try to step back a bit and think about what that code means. Each time we see |... >>= \a -> ...| we can think of |a| as a handle onto the leaves of the tree on the left and the tree on the right is what those leaves get replaced with. If we're going to do lots of grafting with lambda terms like this then it'd be nice to have special syntax. This is exactly what Haskell |do| notation provides. After a |do|, this fragment of code can be written as

<   a <- ...
<   ...

So we can rewrite our code yet again as

> stage3''' = do
>   a <- fork 2 5
>   b <- fork (a+2) (a+5)
>   fork (b+2) (b+5)

Now it really is looking like imperative code with a Unix-like fork function. We have a very straightforward interpretation of |do| notation. The line

< a <- ...

means exactly this: using |a| to represent the value in the leaf, replace all of the leaves on the right hand side with the tree defined by the rest of this |do| block.

\section{The Monad Laws}
There are some properties that we can expect to hold for all trees. The first of these is this: if we graft with the rule |\a -> return a| then we're just replacing a leaf with itself. This rule is the first {\em monad law} and a monad isn't a monad unless it holds. We can write it using |do| notation as:

< x == do
<   a <- x
<   return a

That was a rule for grafting |\a -> return a| into a tree. We can also consider grafting a subtree into a single leaf. This should simply replace the leaf with the tree with no trace of the leaf left behind. So we get the second monad law:

< do
<   a <- return a
<   f a
< ==
< f a

Consider again the two ways of grafting the three stage combinatorial search tree we built above. That again can be expressed purely in the language of monads making no specific reference to the |Tree| type. It is:

< do
<   y <- do
<       x <- m
<       f x
<   g y
< ==
< do
<   x <- m
<   y <- f x
<   g y

The first expression builds a two stage tree |y| and then grafts into that using the function |g|. The second expression grafts a two stage tree directly into the tree m. We'd expect this to hold for any kind of tree and it is known as the third monad law.

The monad laws just express the property that |>>=| is intended to act like tree grafting.

\section{Equating Trees}
Suppose we used the |Tree| monad to perform a combiantorial search and it resulted in the tree |Fork (Leaf 1) (Fork (Leaf 2) (Leaf 3))|. Chances are, this contains more information than we needed. If we only need the leaf values, $1$, $2$ and $3$ then have no need for the tree structure. We could written a function to run through our tree extracting all of the values from it:

> runTree :: Tree a -> [a]
> runTree Nil = []
> runTree (Leaf a) = [a]
> runTree (Fork a b) = runTree a ++ runTree b

It seems a little inefficient to build a tree and then discard it at the end. It would be more efficient to build the list directly as we go along and never make an intermediate tree. But another way to look at it is to consider that a list is itself a type of tree. You can think of the list elements as being the children of a root, but that the children have no children of their own. Here's a picture of the list |[1, 2, 3]|:

\begin{center}
\begin{tikzpicture}
\tikzstyle{level 1}=[sibling distance=2in]
\tikzstyle{level 2}=[sibling distance=1in]
\coordinate
    child {
        node {|Leaf 1|}
    }
    child {
        node {|Leaf 2|}
    }
    child {
        node {|Leaf 2|}
    };
\end{tikzpicture}
\end{center}

The problem now is that grafting seems like it ought to make the tree deeper. The solution is to define grafting for lists in such a way that the resulting tree is flattened back out again. So a tree like
\begin{center}
\begin{tikzpicture}
\tikzstyle{level 1}=[sibling distance=2in]
\tikzstyle{level 2}=[sibling distance=1in]
\coordinate
    child {
        child { node { |Leaf 1| } }
        child { node { |Leaf 2| } }
    }
    child {
        child { node { |Leaf 3| } }
        child { node { |Leaf 4| } }
    }
    child {
        child { node { |Leaf 5| } }
        child { node { |Leaf 6| } }
    };
\end{tikzpicture}
\end{center}
should be immediately flattened out to
\begin{center}
\begin{tikzpicture}
\tikzstyle{level 1}=[sibling distance=1in]
\coordinate
    child { node { |Leaf 1| } }
    child { node { |Leaf 2| } }
    child { node { |Leaf 3| } }
    child { node { |Leaf 4| } }
    child { node { |Leaf 5| } }
    child { node { |Leaf 6| } };
\end{tikzpicture}
\end{center}

We can implement this as follows:

< instance Monad [] where
<   return a = [a]
<   a >>= f = concat (map f a)

Our leaves are simply singleton lists, and the grafting operation temporarily makes a deeper list of lists that is flattened out to a single list using |concat|.

Now we can reimplement |fork| as

> fork' a b = [a,b]

and reimplement our search:

> stage3'''' = do
>   a <- fork' 2 5
>   b <- fork' (a+2) (a+5)
>   fork' (b+2) (b+5)

We don't need the |fork| function. we could have simply written:

> stage3''''' = do
>   a <- [2, 5]
>   b <- [a+2, a+5]
>   [b+2, b+5]

Of course we can put more than two elements into those lists for more complex searches.

But there's one more transformation I want to perform on this code:

> stage3'''''' = do
>   a <- [2, 5]
>   b <- [2, 5]
>   c <- [2, 5]
>   return (a+b+c)

I hope you can see how this works. The last two lines build a list parameterised by the values |a| and |b|. That list is grafted into the list made by the |b <- ...| line. And that list is grafted into the list made at the |a <- ...| line.

There's another way of looking at this code. It's a lot like imperative code. For example the Python

< for a in [2, 5]:
<   for b in [2, 5]:
<       for c in [2, 5]:
<           results.append(a, b, c)

This is a common characteristic of many types of monad: we build a tree structure that represents a computation (for example, an imperative one with loops) and then interpret it using something like |runTree|. In many cases we can do the interpretation as we go along and so we don't need a separate interpretation step at the end, as we just did with lists.

\section{Flowcharts and State}
To illustrate how flexible monads are we'll now look at a completely different type of tree structure that also represents a type of computation and that also shares the |Monad| interface.

Here's a familiar kind of flowchart:

\tikzstyle{decision} = [diamond, draw, fill=blue!20, 
    text width=4.5em, text badly centered, node distance=3cm, inner sep=0pt]
\tikzstyle{block} = [rectangle, draw, fill=blue!20, 
    text width=6em, text centered, rounded corners, minimum height=4em]
\tikzstyle{line} = [draw, -latex']

\begin{center}
\begin{tikzpicture}[node distance = 3cm, auto]
\node[decision] (a) { |get| };
\node[block, below left of = a] (b) { |put True| };
\node[block, below right of = a] (c) { |put False| };
\node[block, below of = b] (d) { |return "No"| };
\node[block, below of = c] (e) { |return "Yes"| };
\path[line] (a.west) -|| node[near start, above] { |False| } (b.north);
\path[line] (a.east) -|| node[near start, above] { |True| } (c.north);
\path[line] (b.south) -- (d.north);
\path[line] (c.south) -- (e.north);
\end{tikzpicture}
\end{center}

For now I want to concentrate on how we build these trees and then later talk about actually getting them to perform an action.

The idea behind this one is that we have a state variable of some type and nodes to set and get this state. The |put| function represents putting its argument into the state, and the |get| function is used to represent a branch depending on the value of the state. We also have leaf nodes representing the final value of our computation.

More precisely, we have a type constructor |State| that builds a flowchart tree type from two types, |s| and |a|. |s| is the type of the state, and |a| is the type of the leaf nodes. We also have two functions, not part of the monad interface, that we can use to construct flowcharts. |put :: s -> State s ()| builds a tree that looks like this:

\begin{center}
\begin{tikzpicture}[node distance = 3cm, auto]
\node[block] (a) { |put x| };
\node[block, below of = a] (b) { |return ()| };
\path[line] (a.south) -- (b.north);
\end{tikzpicture}
\end{center}

This tree represents storing the value |x| in our state. |()| is an element of the type with one element, also called |()|. You can ignore this value, it's just there so that we have a leaf node suitable for grafting.

We also have |get| nodes. In the first flowchart example we use state of type |Bool| so we only needed a two way branch. More generally we have state of type |s| and to cover them all we need infinitely many branches, and it piuts the value of the state into each branch. So, for example, |get :: State s s| can be thought of as looking like

\begin{center}
\begin{tikzpicture}[node distance = 3cm, auto]
\node[decision] (a) { |get| };

\node[block, below of = a] (b) { |return 0| };
\path[line] (a.south) -- node[left] {|0|} (b.north);

\node[block, left of = b] (c) { |return (-1)| };
\path[line] (a.south) -- node[above] {|-1|} (c.north);

\node[left of = c] (e) { $\ldots$ };

\node[block, right of = b] (e) { |return 1| };
\path[line] (a.south) -- node[below] {|1|} (e.north);

\node[block, right of = e] (f) { |return 2| };
\path[line] (a.south) -- node {|2|} (f.north);

\node[right of = f] (g) { $\ldots$ };
\end{tikzpicture}
\end{center}

The labels emerging from the |get| specify which branch is taken as a function of the state. This could get a little unwieldy so it's easier to draw all of the branches emerging from the |get| by a scheme like:

\begin{center}
\begin{tikzpicture}[node distance = 3cm, auto]
\node[decision] (a) { |get| };

\node[block, below of = a] (b) { |return s| };
\path[line] (a.south) -- node[left] {|s|} (b.north);
\end{tikzpicture}
\end{center}

Let's consider an example. We'll construct a block of code which has |Integer| valued state. If the state is odd then it'll add one to it and return the string |"odd"|, otherwise it just returns the string |"even"|. We can draw this is a flowchart:

\begin{center}
\begin{tikzpicture}[node distance = 3cm, auto]
\node[decision] (a) { |get| };

\node[block, below left of = a] (b) { |return "even"| };
\path[line] (a.west) -|| node[above] {|s even|} (b.north);

\node[block, below right of = a] (c) { |put (s+1)| };
\node[block, below of = c] (d) { |return "odd"| };
\path[line] (a.east) -|| node[above] {|s odd|} (c.north);
\path[line] (c.south) -- (d.north);
\end{tikzpicture}
\end{center}



< main = print stage3''''''

\newcommand{\F}{\mathsf}
%format pack  = "\F{pack}"

\newcommand{\pack}{{pack}}
\newcommand{\unpack}{{unpack}}

%\bibliographystyle{plain}
%\bibliography{monads}
\end{document} 
