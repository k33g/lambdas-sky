function fibo(n) 
{
    if (n < 2) return n
    return fibo(n-2) + fibo(n-1)
}

for(var i = 1; i < 10 ; i++)
{
   console.log(i + " = " + fibo(i))
}
