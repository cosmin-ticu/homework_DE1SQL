use classicmodels;

-- Homework 4: INNER join orders,orderdetails,products and customers

-- Iteration 1
select orderNumber, priceEach, quantityOrdered, productName, productLine
from products p
inner join orderdetails od
using (productCode);

-- Iteration 2
select orderNumber, priceEach, quantityOrdered, productName, productLine, orderDate
from products p
inner join orderdetails od
using (productCode)
inner join orders o
using (orderNumber);

-- Iteration 3 - final joint (using USING without aliasing)
select 
	orderNumber, priceEach, quantityOrdered, productName, productLine, city, country, orderDate
from 
	products p
inner join orderdetails od
	using (productCode)
inner join orders o
	using (orderNumber)
inner join customers
	using (customerNumber);