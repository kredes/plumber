#header
<<
#include <map>
#include <string>
#include <iostream>
using namespace std;

// struct to store information about tokens
typedef struct {
  string kind;
  string text;
} Attrib;

// function to fill token information (predeclaration)
void zzcr_attr(Attrib *attr, int type, char *text);

// fields for AST nodes
#define AST_FIELDS string kind; string text;
#include "ast.h"

// macro to create a new AST node (and function predeclaration)
#define zzcr_ast(as,attr,ttype,textt) as=createASTnode(attr,ttype,textt)
AST* createASTnode(Attrib* attr, int ttype, char *textt);
>>

<<
#include <cstdlib>
#include <cmath>

// Symbols Table
map<string, int> m;

void printSymbolTable() {
    cout << endl << endl << "Symbols table" << endl;
    cout << "name  | value" << endl;
    cout << "---------------" << endl;
    for(map<string, int>::const_iterator it = m.begin(); it != m.end(); ++it) {
        cout << it->first << "     | " << it->second << endl;
    }
    cout << endl << endl;
}

// function to fill token information
void zzcr_attr(Attrib *attr, int type, char *text) {
    attr->kind = text;
    attr->text = "";
}

// function to create a new AST node
AST* createASTnode(Attrib* attr, int type, char* text) {
  AST* as = new AST;
  as->kind = attr->kind; 
  as->text = attr->text;
  as->right = NULL; 
  as->down = NULL;
  return as;
}

/// create a new "list" AST node with one element
AST* createASTlist(AST *child) {
 AST *as=new AST;
 as->kind="list";
 as->right=NULL;
 as->down=child;
 return as;
}

/// get nth child of a tree. Count starts at 0.
/// if no such child, returns NULL
AST* child(AST *a,int n) {
 AST *c=a->down;
 for (int i=0; c!=NULL && i<n; i++) c=c->right;
 return c;
} 

/// print AST, recursively, with indentation
void ASTPrintIndent(AST *a,string s)
{
  if (a==NULL) return;

  cout<<a->kind;
  if (a->text!="") cout<<"("<<a->text<<")";
  cout<<endl;

  AST *i = a->down;
  while (i!=NULL && i->right!=NULL) {
    cout<<s+"  \\__";
    ASTPrintIndent(i,s+"  |"+string(i->kind.size()+i->text.size(),' '));
    i=i->right;
  }
  
  if (i!=NULL) {
      cout<<s+"  \\__";
      ASTPrintIndent(i,s+"   "+string(i->kind.size()+i->text.size(),' '));
      i=i->right;
  }
}

/// print AST 
void ASTPrint(AST *a)
{
  while (a!=NULL) {
    cout<<" ";
    ASTPrintIndent(a,"");
    a=a->right;
  }
}

int main() {
  AST *root = NULL;
  ANTLR(plumber(&root), stdin);
  ASTPrint(root);
}
>>

#lexclass START

#token TUBEVECTOR "TUBEVECTOR"
#token OF "OF"
#token PUSH "PUSH"
#token FULL "FULL"
#token EMPTY "EMPTY"
#token POP "POP"

#token TUBE "TUBE"
#token LENGTH "LENGTH"
#token DIAMETER "DIAMETER"
#token SPLIT "SPLIT"

#token CONNECTOR "CONNECTOR"

#token MERGE "MERGE"


#token ENDWHILE "ENDWHILE"
#token WHILE "WHILE"


#token AND "AND"
#token OR "OR"
#token NOT "NOT"

#token GT ">"
#token LT "<"
#token EQ "=="

// Keep the "=" below the "=="!
#token ASSIG "="
#token PLUS "\+"
#token MINUS "\-"
#token TIMES "\*"
#token DIV "/"

#token COMMA ","
#token LPAREN "\("
#token RPAREN "\)"

#token NUM "[0-9]+"
#token ID "[a-zA-Z][0-9a-zA-Z]*"
#token SPACE "[\ \n\t]" << zzskip();>>

plumber: (ops)* <<#0=createASTlist(_sibling);>>;

ops
  : action
  | whileloop
  | function
  ;


/* BOOLEAN
   Boolean expressions with standard precedences. Allows parenthesis. */

//bool: TRUE | FALSE

//boolexpr: (NOT^)* (binary_boolop boolexpr | expr | atom)*

/*
boolexpr
 : LPAREN! boolexpr RPAREN!                     //parenExpression
 | NOT^ boolexpr                                //notExpression
 | boolexpr comparator boolexpr                 //comparatorExpression
 | boolexpr binary boolexpr                     //binaryExpression
 | boolean_function
 | ID                                           //identifierExpression
 | NUM                                          //decimalExpression
 ;
//| bool                                       //boolExpression
*/

//comparator: GT^ | LT^ | EQ^;
//binary: AND | OR;

boolexpr: bterm2 (OR^ bterm2)*;
bterm2: bterm1 (AND^ bterm1);
bterm1
  : NOT^ bterm
  | bterm;
bterm
  : atom (GT^ atom | LT^ atom | EQ^ atom) // Should right atom be expr? Like x > 2 + 3 * 5
  | boolatom; 
boolatom: boolean_function | LPAREN! boolexpr RPAREN!;

 
/*
   LOOPS
*/
list: (ops)* <<#0=createASTlist(_sibling); >>;

whileloop
  : WHILE^ LPAREN! boolexpr RPAREN! list ENDWHILE!;

/* 
   ARITHMETICAL 
   Arithmetical expresions with standard precedences.
   Parenthesis are NOT allowed in these to avoid ambiguities.
*/
expr: term (PLUS^ term | MINUS^ term)*;
term: atom (MULT^ atom | DIV^ atom);

/* Anything other than an arithmetical expression that can be evaluated to
   a numerical value. */
atom: NUM | ID | numerical_function;



/* 
   ACTIONS 
   Whatever thing that does not return any value.
*/
assign
  : ID ASSIG^ (ID | type_function)
  | LPAREN! ID COMMA! ID RPAREN! ASSIG^ split;    // (T1, T2) = SPLIT T3
merge
  : MERGE^ (merge | ID) ID (merge | ID);
pop
  : POP^ ID ID;
push
  : PUSH^ ID ID;

action: assign | merge | pop | push;


/* 
   FUNCTIONS
   Whatever thing that returns a value.
*/
tubevector: TUBEVECTOR^ OF! atom;
tube: TUBE^ atom atom;
connector: CONNECTOR^ atom;

split: SPLIT^ ID;

length: LENGTH^ LPAREN! ID RPAREN!;
diameter: DIAMETER^ LPAREN! ID RPAREN!;

empty: EMPTY^ LPAREN! ID RPAREN!;
full: FULL^ LPAREN! ID RPAREN!;

// SPLIT is NOT included in type_function for convenience
type_function: tubevector | tube | connector | merge;
numerical_function: length | diameter;
boolean_function: empty | full;

function: type_function | numerical_function | boolean_function;
