#header
<<
#include <map>
#include <set>
#include <vector>
#include "dynamic_types.cc"
#include <string>
#include <iostream>
#include <sstream>
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
bool LOCAL = false;
map<string, PlumberType*> m;
set<string> localvars = set<string>();

void printSymbolTable() {
    cout << endl << endl << "SYMBOLS TABLE" << endl;
    cout << "id     | value" << endl;
    cout << "---------------" << endl;
    for(map<string, PlumberType*>::iterator it = m.begin(); it != m.end(); ++it) {
        PlumberType *elem = it->second;
        
        if (elem != NULL) cout << it->first << "      | " << elem->repr() << endl;
        /*
        cout << "Is this element null? ";
        if (it->second == NULL) cout << "Yes." << endl;
        else cout << "No. It is: " << it->first << " -> " << it->second->repr() << endl;
        */
    }
    cout << endl << endl;
}

// function to fill token information
void zzcr_attr(Attrib *attr, int type, char *text) {    
    if (type == ID) {
        attr->kind = "id";
        attr->text = text;
    }
    else if (type == NUM) {
        attr->kind = "integer";
        attr->text = text;
    } else {
        attr->kind = text;
        attr->text = "";
    }
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

/* Forward declaration of evaluators */
int evaluateNumber(AST *a);
bool evaluateBool(AST *a);
Tube* evaluateTube(AST *a);
Tubevector* evaluateVector(AST *a);
Connector* evaluateConnector(AST *a);
pair<Tube*, Tube*> evaluateSplit(AST *a);


void checkIdentifierValidity(PlumberType *elem, AST *origin) {
    if (elem == NULL) {
        stringstream error;
        error << "\t\tERROR: invalid identifier (" << origin->text << ")" << endl;
        
        cout << error.str();
        
        throw InvalidIdentifierException(error.str().c_str());
    }
}

/*
    Evaluates any instruction that yields a single Tube as a result.
    I.e.: TUBE and MERGE
*/
Tube* evaluateTube(AST *a) {
    cout << "\tEvaluating -> " << "kind: " << a->kind << ", text: " << a->text << endl;

    if (a->kind == "TUBE") {
        int length = evaluateNumber(child(a,0));
        int diameter = evaluateNumber(child(a,1));
                
        return new Tube(length, diameter);
        
    } else if (a->kind == "MERGE") {
        Tube *t1 = evaluateTube(child(a,0));
        Connector *c = evaluateConnector(child(a,1));
        Tube *t2 = evaluateTube(child(a,2));
        
        int d1 = t1->diameter;
        int d2 = c->diameter;
        int d3 = t2->diameter;
        if (d1 != d2 or d2 != d3 or d1 != d3) {
            cout << "\t\tERROR: Incompatible diameters (" << d1 << ", " << d2 << ", " << d3 << ")" << endl;
            throw IncompatibleDiameterException("Dummy");
        }
        
        Tube *t = c->merge(t1, t2);
        
        // Check if they're in the map as they might be a temporary element
        // created in a nested instruction
        if (m.find(child(a,0)->text) != m.end())
            m[child(a,0)->text] = NULL;
        if (m.find(child(a,1)->text) != m.end())
            m[child(a,1)->text] = NULL;
        if (m.find(child(a,2)->text) != m.end())
            m[child(a,2)->text] = NULL;
            
        //delete t1;
        //delete c;
        //delete t2;
        
        return t;     
    }
    else if (a->kind == "id") {
        Tube *t = (Tube*) m[a->text];
        checkIdentifierValidity(t, a);
        return t;
    } else {
        stringstream error;
        error << "This shouldn't happen @ evaluateTube(). Was trying to evaluate: ";
        error << "kind: " << a->kind << ", text: " << a->text << endl;
        throw runtime_error(error.str());
    }
}

pair<Tube*, Tube*> evaluateSplit(AST *a) {
    cout << "\tEvaluating -> " << "kind: " << a->kind << ", text: " << a->text << endl;

    if (a->kind == "SPLIT") {
        Tube *t = evaluateTube(child(a,0));
        pair<Tube*, Tube*> p = t->split();
        
        // See MERGE's evaluation of Tube for the explanation of this
        if (m.find(child(a,0)->text) != m.end()) {
            m[child(a,0)->text] = NULL;
        }
        //delete t;
        
        return p;
    } else {
        stringstream error;
        error << "This shouldn't happen @ evaluateSplit(). Was trying to evaluate: ";
        error << "kind: " << a->kind << ", text: " << a->text << endl;
        throw runtime_error(error.str());
    }
}

// Evaluates the TUBEVECTOR instruction
Tubevector* evaluateVector(AST *a) {
    cout << "\tEvaluating -> " << "kind: " << a->kind << ", text: " << a->text << endl;

    if (a->kind == "TUBEVECTOR") {
        int size = evaluateNumber(child(a,0));
        return new Tubevector(size);
    } else if (a->kind == "id") {
        Tubevector *tv = (Tubevector*) m[a->text];
        checkIdentifierValidity(tv, a);
        return tv;
    } else {
        stringstream error;
        error << "This shouldn't happen @ evaluateVector(). Was trying to evaluate: ";
        error << "kind: " << a->kind << ", text: " << a->text << endl;
        throw runtime_error(error.str());
    }
}

Connector* evaluateConnector(AST *a) {
    cout << "\tEvaluating -> " << "kind: " << a->kind << ", text: " << a->text << endl;

    if (a->kind == "CONNECTOR") {
        int diameter = evaluateNumber(child(a,0));
        return new Connector(diameter);
    } else if (a->kind == "id") {
        Connector *c = (Connector*) m[a->text];
        checkIdentifierValidity(c, a);
        return c;
    } else {
        stringstream error;
        error << "This shouldn't happen @ evaluateConnector(). Was trying to evaluate: ";
        error << "kind: " << a->kind << ", text: " << a->text << endl;
        throw runtime_error(error.str());
    }
}

int evaluateNumber(AST *a) {
    cout << "\tEvaluating -> " << "kind: " << a->kind << ", text: " << a->text << endl;

    if (a == NULL) return 0;
    else if (a->kind == "integer")
        return atoi(a->text.c_str());
    else if (a->kind == "LENGTH") {
        Tube *t = evaluateTube(child(a,0));
        return t->length;
    }
    else if (a->kind == "DIAMETER") {
        Tube *t = evaluateTube(child(a,0));
        return t->diameter;
    } else {
        stringstream error;
        error << "This shouldn't happen @ evaluateNumber(). Was trying to evaluate: ";
        error << "kind: " << a->kind << ", text: " << a->text << endl;
        throw runtime_error(error.str());
    }
}

bool evaluateBool(AST *a) {
    cout << "\tEvaluating -> " << "kind: " << a->kind << ", text: " << a->text << endl;

    if (a->kind == "AND")
        return evaluateBool(child(a,0)) and evaluateBool(child(a,1));
    else if (a->kind == "OR")
        return evaluateBool(child(a,0)) or evaluateBool(child(a,1));
    else if (a->kind == "NOT")
        return not evaluateBool(child(a,0));
    else if (a->kind == ">")
        return evaluateNumber(child(a,0)) > evaluateNumber(child(a,1));
    else if (a->kind == "<")
        return evaluateNumber(child(a,0)) < evaluateNumber(child(a,1));
    else if (a->kind == "==")
        return evaluateNumber(child(a,0)) == evaluateNumber(child(a,1));
    else if (a->kind == "FULL") {
        Tubevector *tv = evaluateVector(child(a,0));
        return tv->full();
    } else if (a->kind == "EMPTY") {
        Tubevector *tv = evaluateVector(child(a,0));
        return tv->empty();
    } else {
        stringstream error;
        error << "This shouldn't happen @ evaluateBool(). Was trying to evaluate: ";
        error << "kind: " << a->kind << ", text: " << a->text << endl;
        throw runtime_error(error.str());
    }
}

bool isVariableAssignment(AST *a) {
    AST *child = a->down;
    while (child != NULL) {
        if (child->kind != "id") return false;
        child = child->right;
    }
    return true;
}

void maybeLocal(string id) {
    if (LOCAL) {
        cout << "Is the variable with ID: " << id << " in the Symbol Table?" << endl;
    
        if (m.find(id) != m.end()) return;
        else {
            cout << "Apparently not. BUT, here is the Table" << endl;
            printSymbolTable();
            localvars.insert(id);
        }
    }
}

void execute(AST *a) {
    if (a != NULL) {
        cout << "Executing -> " << "kind: " << a->kind << ", text: " << a->text << endl;
    }

    try {
        if (a == NULL) return;
        else if (a->kind == "=") {
            bool split = child(a,2) == NULL ? false : true;
            if (split) {
                pair<Tube*, Tube*> ev = evaluateSplit(child(a,2));
                
                maybeLocal(child(a,0)->text);
                maybeLocal(child(a,1)->text);
                
                m[child(a,0)->text] = ev.first;
                m[child(a,1)->text] = ev.second;
            } else if (isVariableAssignment(a)) {
                if (child(a,1)->text == "TUBE" or child(a,1)->text == "MERGE") {
                    maybeLocal(child(a,0)->text);
                    m[child(a,0)->text] = evaluateTube(child(a,1));
                }
                else if (child(a,1)->text == "CONNECTOR") {
                    maybeLocal(child(a,0)->text);
                    m[child(a,0)->text] = evaluateConnector(child(a,1));
                }
                else {
                    maybeLocal(child(a,0)->text);
                    m[child(a,0)->text] = evaluateTube(child(a,1));  
                }
            } else {
                AST *aux = child(a,1);
                if (aux->kind == "TUBEVECTOR") {
                    maybeLocal(child(a,0)->text);
                    m[child(a,0)->text] = evaluateVector(aux);
                    //printSymbolTable();
                }
                else if (aux->kind == "CONNECTOR") {
                    maybeLocal(child(a,0)->text);
                    m[child(a,0)->text] = evaluateConnector(aux);
                    //printSymbolTable();
                }
                else if (aux->kind == "TUBE" or aux->kind == "MERGE") {
                    Tube* t = evaluateTube(aux);
                    maybeLocal(child(a,0)->text);
                    m[child(a,0)->text] = t;
                    cout << "\t\tCreated tube with id --" << child(a,0)->text << "-- ";
                    cout << "and length: " << t->length << ", diameter: " << t->diameter << endl;
                    
                    //printSymbolTable();
                }
            }
        } else if (a->kind == "WHILE") {
            bool condition = evaluateBool(child(a,0));
            cout << endl << "------------ WHILE START -------------" << endl;
            printSymbolTable();
            
            LOCAL = true;
            
            while (condition) {
                cout << endl << "------------ ITERATION START -------------" << endl;
                
                execute(child(a,1));
                
                cout << endl << "------------ ITERATION END -------------" << endl;
                printSymbolTable();
                condition = evaluateBool(child(a,0));
            }
            
            LOCAL = false;
            
            cout << localvars.size() << endl;
            
            
            for (set<string>::iterator it = localvars.begin(); it != localvars.end(); ++it) {
                cout << "LOCALVAR: " << *it << endl;
                
                PlumberType *elem = m[*it];
                if (elem != NULL) m[*it] = NULL;
            }
            localvars.clear();
            
            printSymbolTable();
            
            cout << endl << "------------ WHILE END -------------" << endl;
        } else if (a->kind == "PUSH") {
            Tubevector *tv = evaluateVector(child(a,0));
            Tube *t = evaluateTube(child(a,1));
            tv->push(t);
            //cout << "\t\t---- PUSHED TO VECTOR ----" << endl;
        } else if (a->kind == "POP") {
            Tubevector *tv = evaluateVector(child(a,0));
            maybeLocal(child(a,1)->text);
            m[child(a,1)->text] = tv->pop();
        } else if (a->kind == "list") {
            execute(child(a,0));
        }
        // A function
        else cout << evaluateNumber(a) << endl;
    } 
    catch (InvalidIdentifierException &e) {
        //cout << string(e.what()) << endl;
    } catch(IncompatibleDiameterException &e) {
        // pass
    }
    
    execute(a->right);
}

int main() {
  AST *root = NULL;
  ANTLR(plumber(&root), stdin);
  ASTPrint(root);
  execute(root);
  
  printSymbolTable();
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


/* 
   BOOLEAN
   Boolean expressions with standard precedences. Allows parenthesis.
*/
boolexpr: bterm2 (OR^ bterm2)*;
bterm2: bterm1 (AND^ bterm1);
bterm1
  : NOT^ bterm
  | bterm;
bterm
  : expr (GT^ expr | LT^ expr | EQ^ expr)
  | boolatom; 
boolatom: boolean_function | LPAREN! boolexpr RPAREN!;

 
/*
   LOOPS
*/
oplist: (ops)* <<#0=createASTlist(_sibling);>>;

whileloop
  : WHILE^ LPAREN! boolexpr RPAREN! oplist ENDWHILE!;

/* 
   ARITHMETICAL 
   Arithmetical expresions with standard precedences.
   Parenthesis are NOT allowed in these to avoid ambiguities.
*/
expr: term (PLUS^ term | MINUS^ term)*;
term: atom (MULT^ atom | DIV^ atom)*;
atom: NUM | numerical_function;



/* 
   ACTIONS 
   Whatever thing that does not return any value.
*/
assign
  : ID ASSIG^ (ID | type_function)
  | LPAREN! ID COMMA! ID RPAREN! ASSIG^ split;    // (T1, T2) = SPLIT T3
pop
  : POP^ ID ID;
push
  : PUSH^ ID ID;

action: assign | pop | push;


/* 
   FUNCTIONS
   Whatever thing that returns a value.
*/
tubevector: TUBEVECTOR^ OF! expr;
tube: TUBE^ expr expr;
connector: CONNECTOR^ expr;

split: SPLIT^ ID;
merge
  : MERGE^ (merge | ID) ID (merge | ID);

length: LENGTH^ LPAREN! ID RPAREN!;
diameter: DIAMETER^ LPAREN! ID RPAREN!;

empty: EMPTY^ LPAREN! ID RPAREN!;
full: FULL^ LPAREN! ID RPAREN!;

// SPLIT is NOT included in type_function for convenience
type_function: tubevector | tube | connector | merge;
numerical_function: length | diameter;
boolean_function: empty | full;

function: type_function | numerical_function | boolean_function | split;
