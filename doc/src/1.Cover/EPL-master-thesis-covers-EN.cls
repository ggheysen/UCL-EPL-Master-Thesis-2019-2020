% http://ctan.mirrors.hoobly.com/macros/latex/doc/clsguide.pdf
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{src/1.Cover/EPL-master-thesis-covers-EN}[2018/12/04 EPL Master''s Thesis class]

\LoadClass[12pt, a4paper, openright]{report}

% Usefull packages
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage[utf8]{inputenc}
\usepackage[english]{babel}
\RequirePackage{microtype}   % Improves typography
\RequirePackage[T1]{fontenc}
\RequirePackage{lmodern}
\RequirePackage[pdftex]{graphicx}
\RequirePackage{color}
\RequirePackage{geometry}
\RequirePackage{tabto}		 % Tabulation
\RequirePackage{anyfontsize} % size of fonts
\usepackage{afterpage}
\usepackage{float}
\usepackage[nottoc]{tocbibind}
\usepackage{graphicx}
\usepackage{csquotes}
\usepackage{subcaption}
\usepackage[
backend=biber,
style=numeric,
sorting=none,
citestyle=numeric,
maxcitenames=1
]{biblatex}
\usepackage{svg}
\usepackage{listings}
\usepackage{xcolor}
\usepackage{hyperref}
% Load the package
\usepackage[acronym]{glossaries}
\usepackage{algorithm,algpseudocode}
\usepackage{makecell}
% Listing properties
\definecolor{codegreen}{rgb}{0,0.6,0}
\definecolor{codegray}{rgb}{0.5,0.5,0.5}
\definecolor{codepurple}{rgb}{0.58,0,0.82}
\definecolor{backcolour}{rgb}{1,1,1}
\setlength{\parindent}{0em}
\setlength{\parskip}{\baselineskip}

\lstdefinestyle{mystyle}{
    backgroundcolor=\color{backcolour},
    commentstyle=\color{codegreen},
    keywordstyle=\color{magenta},
    numberstyle=\tiny\color{codegray},
    stringstyle=\color{codepurple},
    basicstyle=\ttfamily\footnotesize,
    breakatwhitespace=false,
    breaklines=true,
    captionpos=b,
    keepspaces=true,
    numbers=left,
    numbersep=5pt,
    showspaces=false,
    showstringspaces=false,
    showtabs=false,
    tabsize=2
}

\lstset{style=mystyle}

% Generate the glossary
\makenoidxglossaries

% Bibliography
\addbibresource{src/0.Bibliography/thesis.bib}

% Commands for title, readers, authors, dates, specialities,...
\RequirePackage{etoolbox}
\newcommand{\subtitle}[1]{\def\@subtitle{#1}}
\newcommand{\secondauthor}[1]{\def\@secondauthor{#1}}
\newcommand{\thirdauthor}[1]{\def\@thirdauthor{#1}}
\newcommand{\supervisor}[1]{\def\@supervisor{#1}}
\newcommand{\secondsupervisor}[1]{\def\@secondsupervisor{#1}}
\newcommand{\thirdsupervisor}[1]{\def\@thirdsupervisor{#1}}
\newcommand{\degreetitle}[1]{\def\@degreetitle{#1}}
\newcommand{\options}[1]{\def\@myoptions{#1}}
\newcommand{\readerone}[1]{\def\@readerone{#1}}
\newcommand{\readertwo}[1]{\def\@readertwo{#1}}
\newcommand{\readerthree}[1]{\def\@readerthree{#1}}
\newcommand{\readerfour}[1]{\def\@readerfour{#1}}
\newcommand{\readerfive}[1]{\def\@readerfive{#1}}
\newcommand{\years}[1]{\def\@years{#1}}
\newcommand\blankpage{%
    \null
    \thispagestyle{empty}%
    \addtocounter{page}{-1}%
    \newpage}
\usepackage{titlesec}
\titleclass{\part}{top}
\titleformat{\part}[display]
  {\normalfont\huge\bfseries}{\centering\partname\ \thepart}{20pt}{\Huge\centering}
\titlespacing*{\part}{0pt}{50pt}{40pt}
\titleclass{\chapter}{straight}
\titleformat{\chapter}[display]
  {\normalfont\huge\bfseries}{\chaptertitlename\ \thechapter}{20pt}{\Huge}
\titlespacing*{\chapter} {0pt}{50pt}{40pt}

% Lenghts
\newlength{\tabAuthor}
\newlength{\tabSupervisor}
\newlength{\tabReader}

% Title creation
\renewcommand{\maketitle}{
  \begin{titlepage}
    \thispagestyle{empty}
    \newgeometry{top=0cm,bottom=0cm,left=3cm,right=2.5cm}

    % background
    \noindent \hspace{-3cm}
    \includegraphics{src/1.Cover/_frontbanner_EPL-master-thesis.pdf}\\
    \vspace*{-\textheight}

    % Font
    \color{white} \fontfamily{phv} \selectfont

    % Define lengths
    \setlength{\tabAuthor}{
		\ifdef{\@secondauthor}{1.7cm}{1.6cm}
	}
    \setlength{\tabSupervisor}{
		\ifdef{\@secondsupervisor}{2.55cm}{2.45cm}
	}
    \setlength{\tabReader}{
		\ifdef{\@readertwo}{1.9cm}{1.8cm}
	}

	\vspace*{9cm}

    % Title and subtitle
    \noindent
    \begin{minipage}[t][10cm][c]{1\textwidth}
    \raggedright
    %\vspace*{2cm}
    {
      \fontsize{26}{36}\selectfont \textbf{\@title}

      \vspace*{12pt}

      \ifdef{\@subtitle}{\fontsize{20}{30} \selectfont \@subtitle}{$ $} \\
    }
    \end{minipage}


    % Metadata
    \vspace*{4cm}
    \noindent \hspace{1.7cm}
    \begin{minipage}[l]{.85\textwidth}
	  % authors
      \ifdef{\@secondauthor}{Authors:}{Author:}{\bfseries
        \tabto{\tabAuthor}\@author
        \ifdef{\@secondauthor}{, \@secondauthor}{}
        \ifdef{\@thirdauthor}{, \@thirdauthor}{}}
      \\
      % supervisors
      \ifdef{\@secondsupervisor}{Supervisors:}{Supervisor:}{\bfseries
		\tabto{\tabSupervisor}\@supervisor
		\ifdef{\@secondsupervisor}{, \@secondsupervisor}{}\ifdef{\@thirdsupervisor}{, \@thirdsupervisor}{}}
      \\
      % readers
      \ifdef{\@readertwo}{Readers:}{Reader:}{\bfseries
		\tabto{\tabReader}\@readerone
		\ifdef{\@readertwo}{, \@readertwo}{}\ifdef{\@readerthree}{, \@readerthree}{}\ifdef{\@readerfour}{, \@readerfour}{}\ifdef{\@readerfive}{, \@readerfive}{}}
	  \\
	  % academic year
	  Academic year \@years
	  \\
      % degree title
      \@degreetitle
    \end{minipage}
  \end{titlepage}
}

% Front cover page
\newcommand{\frontpage}
{
  \begin{titlepage}
  \end{titlepage}
}

% Back cover page
\newcommand{\backcoverpage}
{
  \newpage
  \thispagestyle{empty}
  \newgeometry{top=0cm,bottom=0cm,left=0cm,right=0cm}
  \includegraphics{src/1.Cover/_backbanner_EPL-master-thesis.pdf}

}

\endinput
