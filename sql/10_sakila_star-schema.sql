-- Name: sakila_star


CREATE DATABASE IF NOT EXISTS sakila_star;
USE sakila_star;


--
-- Grant permissions to the 'app' user defined in docker-compose
--

-- We use '%' to allow connection from any host (required for docker networking)
GRANT ALL PRIVILEGES ON sakila_star.* TO 'app'@'%';
FLUSH PRIVILEGES;

--
-- ETL watermark table (one watermark for this pipeline)
--

-- DROP TABLE IF EXISTS etl_state;
CREATE TABLE IF NOT EXISTS etl_state (
  pipeline_name VARCHAR(100) PRIMARY KEY,
  last_success_ts DATETIME NOT NULL
);

INSERT INTO etl_state(pipeline_name, last_success_ts)
VALUES
  ('fact_rental', '1900-01-01'),
  ('dim_film', '1900-01-01'),
  ('dim_actor', '1900-01-01'),
  ('dim_category', '1900-01-01'),
  ('dim_customer', '1900-01-01'),
  ('dim_staff', '1900-01-01'),
  ('dim_store', '1900-01-01')
ON DUPLICATE KEY UPDATE pipeline_name = pipeline_name;
-- ON DUPLICATE KEY UPDATE last_success_ts = VALUES(last_success_ts);

-- --
-- -- Table structure for table `fact_rental`
-- --

-- -- DROP TABLE IF EXISTS fact_rental;
-- CREATE TABLE IF NOT EXISTS fact_rental (
--   rental_id INT UNSIGNED NOT NULL PRIMARY KEY,
--   rental_date DATETIME NOT NULL,
--   return_date DATETIME NULL,
--   inventory_id MEDIUMINT UNSIGNED NOT NULL,
--   amount DECIMAL(5,2) NULL,
--   payment_date DATETIME NULL,
--   film_id INT UNSIGNED NOT NULL,
--   category_id SMALLINT UNSIGNED NOT NULL,
--   customer_id INT UNSIGNED NOT NULL,
--   staff_id SMALLINT UNSIGNED NOT NULL,
--   store_id SMALLINT UNSIGNED NOT NULL,
--   src_last_update TIMESTAMP NOT NULL,  -- from sakila.rental.last_update (your watermark basis)
--   etl_loaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--   KEY idx_rental_date (rental_date),
--   KEY idx_customer_id (customer_id),
--   KEY idx_film_id (film_id),
--   KEY idx_store_id (store_id)
-- );



-- -- FILM-RELATED TABLES --

-- --
-- -- Table structure for table `dim_actor`
-- --

-- -- DROP TABLE IF EXISTS dim_actor;
-- CREATE TABLE IF NOT EXISTS dim_actor (
--   actor_id INT UNSIGNED NOT NULL PRIMARY KEY,
--   first_name VARCHAR(45),
--   last_name VARCHAR(45),
--   src_last_update TIMESTAMP NOT NULL,  -- from sakila.actor.last_update
--   etl_loaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
-- );


-- --
-- -- Table structure for table `bridge_actor`
-- --

-- -- DROP TABLE IF EXISTS bridge_actor;
-- CREATE TABLE IF NOT EXISTS bridge_actor (
--   actor_id INT UNSIGNED NOT NULL,
--   rental_id INT UNSIGNED NOT NULL,
--   src_last_update TIMESTAMP NOT NULL,  -- from sakila.actor.last_update
--   etl_loaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--   PRIMARY KEY (actor_id, rental_id),
--   KEY idx_actor_id (actor_id),
--   KEY idx_rental_id (rental_id),
--   FOREIGN KEY (actor_id) REFERENCES dim_actor(actor_id),
--   FOREIGN KEY (rental_id) REFERENCES fact_rental(rental_id)
-- );

-- --
-- -- Table structure for table `dim_category`
-- --

-- -- DROP TABLE IF EXISTS dim_category;
-- CREATE TABLE IF NOT EXISTS dim_category (
--   category_id TINYINT UNSIGNED NOT NULL PRIMARY KEY,
--   name VARCHAR(25),
--   src_last_update TIMESTAMP NOT NULL,  -- from sakila.category.last_update
--   etl_loaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
-- );


-- --
-- -- Table structure for table `dim_film`
-- --

-- -- DROP TABLE IF EXISTS dim_film;
-- CREATE TABLE IF NOT EXISTS dim_film (
--   film_id INT UNSIGNED NOT NULL PRIMARY KEY,
--   title VARCHAR(128),
--   description TEXT,
--   release_year YEAR,
--   language_name CHAR(20),
--   rental_duration TINYINT UNSIGNED NOT NULL DEFAULT 3,
--   rental_rate DECIMAL(4,2) NOT NULL DEFAULT 4.99,
--   length SMALLINT UNSIGNED,
--   replacement_cost DECIMAL(5,2) NOT NULL DEFAULT 19.99,
--   rating ENUM('G','PG','PG-13','R','NC-17') DEFAULT 'G',
--   src_last_update TIMESTAMP NOT NULL,  -- from sakila.film.last_update
--   etl_loaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
-- );


-- -- STORE-RELATED TABLES --

-- --
-- -- Table structure for table `dim_store`
-- --

-- -- DROP TABLE IF EXISTS dim_store;
-- CREATE TABLE IF NOT EXISTS dim_store (
--   store_id SMALLINT UNSIGNED NOT NULL PRIMARY KEY,
--   address VARCHAR(50),
--   address2 VARCHAR(50),
--   district VARCHAR(20),
--   city VARCHAR(50),
--   country VARCHAR(50),
--   postal_code VARCHAR(10),
--   phone VARCHAR(20),
--   src_last_update TIMESTAMP NOT NULL,  -- from sakila.store.last_update
--   etl_loaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
-- );


-- -- STAFF-RELATED TABLES --

-- --
-- -- Table structure for table `dim_staff`
-- --

-- -- DROP TABLE IF EXISTS dim_staff;
-- CREATE TABLE IF NOT EXISTS dim_staff (
--   staff_id SMALLINT UNSIGNED NOT NULL PRIMARY KEY,
--   first_name VARCHAR(45) NOT NULL,
--   last_name VARCHAR(45) NOT NULL,
--   email VARCHAR(50),
--   active TINYINT(1) NOT NULL DEFAULT 1,
--   username VARCHAR(16) NOT NULL,
--   password VARCHAR(40),
--   picture BLOB,
--   address VARCHAR(50),
--   address2 VARCHAR(50),
--   district VARCHAR(20),
--   city VARCHAR(50),
--   country VARCHAR(50),
--   postal_code VARCHAR(10),
--   phone VARCHAR(20),
--   src_last_update TIMESTAMP NOT NULL,  -- from sakila.staff.last_update
--   etl_loaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
-- );


-- -- CUSTOMER-RELATED TABLES --

-- --
-- -- Table structure for table `dim_customer`
-- --

-- -- DROP TABLE IF EXISTS dim_customer;
-- CREATE TABLE IF NOT EXISTS dim_customer (
--   customer_id INT UNSIGNED NOT NULL PRIMARY KEY,
--   store_id SMALLINT UNSIGNED NOT NULL,
--   first_name VARCHAR(45),
--   last_name VARCHAR(45),
--   email VARCHAR(50),
--   activebool TINYINT(1) NOT NULL DEFAULT 1,
--   create_date DATETIME,
--   active TINYINT UNSIGNED,
--   address VARCHAR(50),
--   address2 VARCHAR(50),
--   district VARCHAR(20),
--   city VARCHAR(50),
--   country VARCHAR(50),
--   postal_code VARCHAR(10),
--   phone VARCHAR(20),
--   src_last_update TIMESTAMP NOT NULL,  -- from sakila.customer.last_update
--   etl_loaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
--   KEY idx_store_id (store_id),
--   FOREIGN KEY (store_id) REFERENCES dim_store(store_id)
-- );
