## Programming Assignment 2 for rprog-006

## The makeCacheMatrix function creates a special "matrix",
## which is essentially a list containing functions to:
##  1. set the value of the matrix, set()
##  2. get the value of the matrix, get()
##  3. set the value of the matrix's inverse, setinverse()
##  4. get the value of the matrix's inverse, getinverse()

makeCacheMatrix <- function(x = matrix()) {
        
    # Initially, matrix inverse cache is NULL since it 
    # does not contain a stored value.
    inv <- NULL

    # 1. Function to set value of matrix x to given value, newx.
    set <- function(newx) {
        # The <<- operator above will search the parent
        # environment to find the existing value of x.
        x <<- newx   
        # set inv to NULL because we have not cached newx's inverse.
        inv <<- NULL
                
    }
    
    # 2. Function to get value of matrix.
    get <- function() {
        # just return the matrix, x.
        x 
    }
    
    # 3. Function to set value of inverse to given value.
    setinverse <- function(inverse) {
        # Must use <<- operator here, so that the 
        # cacheSolve() function can store inverse
        # in the correct place: inv.
        inv <<- inverse
    }
    
    # 4. Function to get cached value of inverse.
    getinverse <- function() {
        # return the cached inverse, inv.
        inv 
    }
    
    # Finally, return a list that contains these functions.
    list(set = set, 
         get = get, 
         setinverse = setinverse,
         getinverse = getinverse)
}


## The cacheSolve() function computes the inverse of the 
## special "matrix" created with makeCacheMatrix(). 
## First it checks whether the inverse has already been computed. 
## If yes, it gets the inverse from the cache and skips the computation.
## If not, it computes the inverse of the matrix. Then, it sets 
## the value of the inverse in the cache using function setinverse.

cacheSolve <- function(x, ...) {
    ## Return a matrix that is the inverse of 'x'
    
    # Check if inverse of given matrix has been computed.
    # Remember that the special "matrix" x is really a list.
    # We can use the function getinverse() that's inside the list.
    inv <- x$getinverse()
    
    # Check if inv is NULL. 
    # If inv != NULL, retrieve cached value and return it.
    if (!is.null(inv)) {
        message('Getting cached inverse...')
        return(inv)
    }
    
    # If inv == NULL, that means x's inverse has not been computed.
    # So we need to compute inverse, and store in cache.
    data <- x$get()
    
    # Use solve() function. 
    # solve(matrix) returns inverse of an n*n matrix.
    inv <- solve(data, ...)
    
    # Finally, store freshly computed inverse value in cache.
    # Note: this function should not be called by the user!
    x$setinverse(inv)
    
    # Display the inverse that we obtained.
    inv
}
