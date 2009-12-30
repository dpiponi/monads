monads.pdf: monads.ps
	ps2pdf monads.ps

monads.tex: monads.lhs
	lhs2TeX monads.lhs > monads.tex

monads.hs: monads.tex strip
	./strip < monads.tex > monads.hs

strip: strip.hs
	ghc -O2 -o strip strip.hs

monads.ps: monads.dvi
	dvips -Ppdf -G0 monads.dvi -o monads.ps

monads.dvi: monads.tex # monads.mps
	latex monads.tex
#	bibtex monads
#	latex monads.tex
#	latex monads.tex

# monads.mps: monads.mp
# 	mpost -parse-first-line monads.mp
# 	mv monads.1 monads.1.mps
# 	mv monads.2 monads.2.mps
