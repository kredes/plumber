#include <utility>
#include <vector>
#include <iostream>
#include <sstream>

using namespace std;

class PlumberType {
public:
    virtual string repr() {};
};


class Tube : public PlumberType {
public:
    int length, diameter;
    
    Tube() {}
    
    Tube(int length, int diameter) {
        this->length = length;
        this->diameter = diameter;
    }
    
    
    pair<Tube*, Tube*> split() {
        int l1, l2;
        
        if (length % 2 == 0) {
            l1 = length/2;
            l2 = length/2;
        } else {
            l1 = length/2;
            l2 = (length/2) + 1;
        }
        return make_pair(new Tube(l1, diameter), new Tube(l2, diameter));
    }
    
    string repr() {  
        stringstream os;
        os << "Tube(" << length << ", " << diameter << ")";  
        return os.str();  
    }
    
};

class Connector : public PlumberType {
public:
    int diameter;
    
    Connector() {}
    
    Connector(int diameter) {
        this->diameter = diameter;
    }
    
    Tube* merge(Tube* t1, Tube* t2) {
        return new Tube(t1->length + t2->length, diameter);
    }
    
    string repr() {
        stringstream os;
        os << "Connector(" << diameter << ")";  
        return os.str();  
    }
};

class Tubevector : public PlumberType {
public:
    
    vector<Tube*> tubes;
    int max_size;
    
    Tubevector() {}
    
    Tubevector(int max_size) {
        this->max_size = max_size;
        this->tubes = vector<Tube*>();
    }
    
    void push(Tube* t) {
        /*
        if (this->full()) {
            stringstream error;
            error << "Tubevector is full (current size: " << tubes.size() << ", max size: " << max_size << ")" << endl;
            throw runtime_error(error.str());
        }*/
        tubes.push_back(t);
    }
    
    Tube* pop() {
        /*
        if (tubes.size() == 0) {
            stringstream error;
            error << "Tubevector is empty (current size: " << tubes.size() << ", max size: " << max_size << ")" << endl;
            throw runtime_error(error.str());
        }*/
        
        Tube *t = tubes.back();
        tubes.pop_back();
        
        return t;
    }
    
    bool empty() { return tubes.empty(); }
    
    bool full() { return tubes.size() == max_size; }
    
    string repr() {  
        stringstream os;
        
        os << "Tubevector(" << max_size << ") -> [";  
        for (int i = 0; i < max_size; ++i) {
            if (i < tubes.size()) os << tubes[i]->repr();
            else os << "_";
            
            if (i < max_size - 1) os << ", ";
        }
        os << "]";
        
        return os.str();  
    }
};

class InvalidIdentifierException : public exception {
public:
    InvalidIdentifierException(const char* errMessage):errMessage_(errMessage){}

    const char* what() const throw() { return errMessage_; }
 
private:
    const char* errMessage_;
};

class IncompatibleDiameterException : public exception {
public:
    IncompatibleDiameterException(const char* errMessage):errMessage_(errMessage){}

    const char* what() const throw() { return errMessage_; }
 
private:
    const char* errMessage_;
};

class TubevectorCapacityException : public exception {
public:
    TubevectorCapacityException(const char* errMessage):errMessage_(errMessage){}

    const char* what() const throw() { return errMessage_; }
 
private:
    const char* errMessage_;
};