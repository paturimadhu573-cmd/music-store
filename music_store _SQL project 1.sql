create database music_store;
use music_store;
CREATE TABLE Genre (
	genre_id INT PRIMARY KEY,
	name VARCHAR(120)
);
CREATE TABLE MediaType (
	media_type_id INT PRIMARY KEY,
	name VARCHAR(120)
);
CREATE TABLE Employee (
	employee_id INT PRIMARY KEY,
	last_name VARCHAR(120),
	first_name VARCHAR(120),
	title VARCHAR(120),
	reports_to INT,
  levels VARCHAR(255),
	birthdate DATE,
	hire_date DATE,
	address VARCHAR(255),
	city VARCHAR(100),
	state VARCHAR(100),
	country VARCHAR(100),
	postal_code VARCHAR(20),
	phone VARCHAR(50),
	fax VARCHAR(50),
	email VARCHAR(100)
);
CREATE TABLE Customer (
	customer_id INT PRIMARY KEY,
	first_name VARCHAR(120),
	last_name VARCHAR(120),
	company VARCHAR(120),
	address VARCHAR(255),
	city VARCHAR(100),
	state VARCHAR(100),
	country VARCHAR(100),
	postal_code VARCHAR(20),
	phone VARCHAR(50),
	fax VARCHAR(50),
	email VARCHAR(100),
	support_rep_id INT,
	FOREIGN KEY (support_rep_id) REFERENCES Employee(employee_id)
);
CREATE TABLE Artist (
	artist_id INT PRIMARY KEY,
	name VARCHAR(120)
);
CREATE TABLE Album (
	album_id INT PRIMARY KEY,
	title VARCHAR(160),
	artist_id INT,
	FOREIGN KEY (artist_id) REFERENCES Artist(artist_id)
);
CREATE TABLE Track (
	track_id INT PRIMARY KEY,
	name VARCHAR(200),
	album_id INT,
	media_type_id INT,
	genre_id INT,
	composer VARCHAR(220),
	milliseconds INT,
	bytes INT,
	unit_price DECIMAL(10,2),
	FOREIGN KEY (album_id) REFERENCES Album(album_id),
	FOREIGN KEY (media_type_id) REFERENCES MediaType(media_type_id),
	FOREIGN KEY (genre_id) REFERENCES Genre(genre_id)
);
CREATE TABLE Invoice (
	invoice_id INT PRIMARY KEY,
	customer_id INT,
	invoice_date DATE,
	billing_address VARCHAR(255),
	billing_city VARCHAR(100),
	billing_state VARCHAR(100),
	billing_country VARCHAR(100),
	billing_postal_code VARCHAR(20),
	total DECIMAL(10,2),
	FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);
CREATE TABLE InvoiceLine (
	invoice_line_id INT PRIMARY KEY,
	invoice_id INT,
	track_id INT,
	unit_price DECIMAL(10,2),
	quantity INT,
	FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
	FOREIGN KEY (track_id) REFERENCES Track(track_id)
);
CREATE TABLE Playlist (
 	playlist_id INT PRIMARY KEY,
	name VARCHAR(255)
);
CREATE TABLE PlaylistTrack (
	playlist_id INT,
	track_id INT,
	PRIMARY KEY (playlist_id, track_id),
	FOREIGN KEY (playlist_id) REFERENCES Playlist(playlist_id),
	FOREIGN KEY (track_id) REFERENCES Track(track_id)
);


select *from album;
select *from artist;
select *from customer;
select *from employee;
select *from genre;
select *from invoice;
select *from invoiceline;
select *from mediatype;
select *from playlist;
select *from playlisttrack;
select *from track;

-- 1 Find the senior-most employee based on job title?
SELECT first_name, last_name, title,hire_date
FROM Employee
ORDER BY hire_date
LIMIT 1;

-- 2 Which countries generate the most invoices?
SELECT billing_country, COUNT(invoice_id) AS total_invoices
FROM Invoice
GROUP BY billing_country
ORDER BY total_invoices DESC;

-- 3 Which are the top 3 invoices by total value?
SELECT total
FROM Invoice
ORDER BY total DESC
LIMIT 3;

-- 4 Which city has generated the most revenue from invoices?
SELECT billing_city, SUM(total) AS total_invoice_amount
FROM Invoice
GROUP BY billing_city
ORDER BY total_invoice_amount DESC
LIMIT 1;

-- 5 Who is the best customer overall?
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_spent
FROM Customer c
JOIN Invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 1;

-- 6 List all Rock music listeners with their email, name, and genre?
SELECT DISTINCT
    c.first_name,
    c.last_name,
    c.email,
    g.name AS genre
FROM customer AS c
JOIN invoice AS i 
    ON c.customer_id = i.customer_id
JOIN invoiceline AS il 
    ON i.invoice_id = il.invoice_id
JOIN track AS t 
    ON il.track_id = t.track_id
JOIN genre AS g 
    ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.first_name, c.last_name;

SELECT DISTINCT c.email, c.first_name, c.last_name, g.name AS genre
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoiceLine il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.Name = 'Rock'
ORDER BY c.email ASC;

-- 7 Which 10 artists have the most Rock tracks?
SELECT 
    ar.name AS artist_name,
    COUNT(t.track_id) AS total_tracks
FROM track AS t
JOIN genre AS g 
    ON t.genre_id = g.genre_id
JOIN album AS al 
    ON t.album_id = al.album_id
JOIN artist AS ar 
    ON al.artist_id = ar.artist_id
WHERE g.name = 'Rock'
GROUP BY ar.artist_id, ar.name
ORDER BY total_tracks DESC
LIMIT 10;

-- 8 Tracks longer than avg song length?
SELECT name, milliseconds
FROM Track
WHERE milliseconds > (
    SELECT AVG(milliseconds) FROM Track
)
ORDER BY milliseconds DESC;

-- 9 How much has each customer spent on each artist? 

SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    ar.name AS artist_name,
    SUM(il.unit_price * il.quantity) AS total_spent
FROM invoice AS i
JOIN customer AS c 
    ON i.customer_id = c.customer_id
JOIN invoiceline AS il          -- FIXED table name
    ON i.invoice_id = il.invoice_id
JOIN track AS t 
    ON il.track_id = t.track_id
JOIN album AS al 
    ON t.album_id = al.album_id
JOIN artist AS ar 
    ON al.artist_id = ar.artist_id
GROUP BY 
    customer_name, 
    ar.name
ORDER BY 
    total_spent DESC
LIMIT 1000;



-- 10  Who is the top-spending customer in each country?
WITH customer_spending AS (
    SELECT c.country, c.first_name || ' ' || c.last_name AS customer_name,
           SUM(i.total) AS total_spent
    FROM Customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.country, c.first_name, c.last_name
),
ranked AS (
    SELECT country, customer_name, total_spent,
           RANK() OVER (PARTITION BY country ORDER BY total_spent DESC) AS spend_rank
    FROM customer_spending
)
SELECT country, customer_name, total_spent
FROM ranked
WHERE spend_rank = 1
ORDER BY country;

-- 11 Most popular music genre by country.
WITH genre_sales AS (
    SELECT c.country, g.name AS genre_name, COUNT(il.quantity) AS purchases
    FROM invoice i
    JOIN customer c ON i.customer_id = c.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.name
),
ranked AS (
    SELECT country, genre_name, purchases,
           RANK() OVER (PARTITION BY country ORDER BY purchases DESC) AS genre_rank
    FROM genre_sales
)
SELECT country, genre_name, purchases
FROM ranked
WHERE genre_rank = 1
ORDER BY country;
select *from invoiceline;

SELECT 
    t1.country,
    t1.genre_name,
    t1.total_purchases
FROM (
   -- Count how many tracks of each genre were purchased in each country 
    SELECT 
        c.country,
        g.name AS genre_name,
        SUM(il.quantity) AS total_purchases,
        ROW_NUMBER() OVER (
            PARTITION BY c.country 
            ORDER BY SUM(il.quantity) DESC
        ) AS rn
    FROM invoiceline AS il
    JOIN invoice AS i 
        ON il.invoice_id = i.invoice_id
    JOIN customer AS c 
        ON i.customer_id = c.customer_id
    JOIN track AS t 
        ON il.track_id = t.track_id
    JOIN genre AS g 
        ON t.genre_id = g.genre_id
    GROUP BY 
        c.country,
        g.name
) AS t1
WHERE t1.rn = 1            
ORDER BY t1.country;
