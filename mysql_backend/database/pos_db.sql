-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Oct 23, 2025 at 08:40 AM
-- Server version: 8.0.30
-- PHP Version: 8.2.29

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `pos_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `parent_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `icon` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'SYNCED',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `deleted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text COLLATE utf8mb4_unicode_ci,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `postal_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `points` int DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1',
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'SYNCED',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `deleted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pending_transactions`
--

CREATE TABLE `pending_transactions` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pending_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `customer_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `customer_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `saved_at` datetime NOT NULL,
  `saved_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `subtotal` decimal(15,2) NOT NULL,
  `tax` decimal(15,2) NOT NULL DEFAULT '0.00',
  `discount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `total` decimal(15,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pending_transaction_items`
--

CREATE TABLE `pending_transaction_items` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pending_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `product_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `product_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` int NOT NULL,
  `price` decimal(15,2) NOT NULL,
  `discount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `subtotal` decimal(15,2) NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `plu` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `barcode` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `category_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `unit` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `purchase_price` decimal(15,2) NOT NULL,
  `selling_price` decimal(15,2) NOT NULL,
  `stock` int NOT NULL DEFAULT '0',
  `min_stock` int DEFAULT '0',
  `image_url` text COLLATE utf8mb4_unicode_ci,
  `is_active` tinyint(1) DEFAULT '1',
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'SYNCED',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `deleted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchases`
--

CREATE TABLE `purchases` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `purchase_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `supplier_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `supplier_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `purchase_date` datetime NOT NULL,
  `subtotal` decimal(15,2) NOT NULL,
  `tax` decimal(15,2) NOT NULL DEFAULT '0.00',
  `discount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `total` decimal(15,2) NOT NULL,
  `payment_method` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `paid_amount` decimal(15,2) NOT NULL,
  `status` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_items`
--

CREATE TABLE `purchase_items` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `purchase_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `product_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `product_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` int NOT NULL,
  `price` decimal(15,2) NOT NULL,
  `subtotal` decimal(15,2) NOT NULL,
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'SYNCED',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_returns`
--

CREATE TABLE `purchase_returns` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `return_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `receiving_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `receiving_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `purchase_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `purchase_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `supplier_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `supplier_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `return_date` datetime NOT NULL,
  `subtotal` decimal(15,2) NOT NULL,
  `item_discount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `item_tax` decimal(15,2) NOT NULL DEFAULT '0.00',
  `total_discount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `total_tax` decimal(15,2) NOT NULL DEFAULT '0.00',
  `total` decimal(15,2) NOT NULL,
  `status` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `reason` text COLLATE utf8mb4_unicode_ci,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `processed_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_return_items`
--

CREATE TABLE `purchase_return_items` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `return_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `receiving_item_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `product_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `product_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `received_quantity` int NOT NULL,
  `return_quantity` int NOT NULL,
  `price` decimal(15,2) NOT NULL,
  `discount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `discount_type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'AMOUNT',
  `tax` decimal(15,2) NOT NULL DEFAULT '0.00',
  `tax_type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'AMOUNT',
  `subtotal` decimal(15,2) NOT NULL,
  `total` decimal(15,2) NOT NULL,
  `reason` text COLLATE utf8mb4_unicode_ci,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'SYNCED',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `receivings`
--

CREATE TABLE `receivings` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `receiving_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `purchase_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `purchase_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `supplier_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `supplier_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `receiving_date` datetime NOT NULL,
  `invoice_number` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `delivery_order_number` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vehicle_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `driver_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `subtotal` decimal(15,2) NOT NULL,
  `item_discount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `item_tax` decimal(15,2) NOT NULL DEFAULT '0.00',
  `total_discount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `total_tax` decimal(15,2) NOT NULL DEFAULT '0.00',
  `total` decimal(15,2) NOT NULL,
  `status` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'COMPLETED',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `received_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `receiving_items`
--

CREATE TABLE `receiving_items` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `receiving_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `purchase_item_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `product_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `product_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `po_quantity` int NOT NULL,
  `po_price` decimal(15,2) NOT NULL,
  `received_quantity` int NOT NULL,
  `received_price` decimal(15,2) NOT NULL,
  `discount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `discount_type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'AMOUNT',
  `tax` decimal(15,2) NOT NULL DEFAULT '0.00',
  `tax_type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'AMOUNT',
  `subtotal` decimal(15,2) NOT NULL,
  `total` decimal(15,2) NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'SYNCED',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `settings`
--

CREATE TABLE `settings` (
  `setting_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `setting_value` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `stock_movements`
--

CREATE TABLE `stock_movements` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `product_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` int NOT NULL,
  `reference_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reference_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `user_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `suppliers`
--

CREATE TABLE `suppliers` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_person` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text COLLATE utf8mb4_unicode_ci,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `postal_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tax_number` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payment_terms` int DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1',
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'SYNCED',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `deleted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sync_queue`
--

CREATE TABLE `sync_queue` (
  `id` int NOT NULL,
  `table_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `record_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `operation` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `data` json DEFAULT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `retry_count` int DEFAULT '0',
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL,
  `synced_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `transaction_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `customer_id` varchar(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cashier_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cashier_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtotal` decimal(15,2) NOT NULL,
  `tax` decimal(15,2) NOT NULL DEFAULT '0.00',
  `discount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `total` decimal(15,2) NOT NULL,
  `payment_method` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payment_amount` decimal(15,2) NOT NULL,
  `change_amount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `status` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `transaction_date` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `transaction_items`
--

CREATE TABLE `transaction_items` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `transaction_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `product_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `product_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` int NOT NULL,
  `price` decimal(15,2) NOT NULL,
  `discount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `subtotal` decimal(15,2) NOT NULL,
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `last_login` datetime DEFAULT NULL,
  `sync_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'SYNCED',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_categories_parent` (`parent_id`);

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `idx_customers_code` (`code`),
  ADD KEY `idx_customers_phone` (`phone`);

--
-- Indexes for table `pending_transactions`
--
ALTER TABLE `pending_transactions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `pending_number` (`pending_number`),
  ADD KEY `idx_pending_number` (`pending_number`),
  ADD KEY `idx_saved_at` (`saved_at`);

--
-- Indexes for table `pending_transaction_items`
--
ALTER TABLE `pending_transaction_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_pending_id` (`pending_id`),
  ADD KEY `idx_product_id` (`product_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `plu` (`plu`),
  ADD UNIQUE KEY `barcode` (`barcode`),
  ADD KEY `idx_products_plu` (`plu`),
  ADD KEY `idx_products_barcode` (`barcode`),
  ADD KEY `idx_products_category` (`category_id`),
  ADD KEY `idx_products_sync` (`sync_status`);

--
-- Indexes for table `purchases`
--
ALTER TABLE `purchases`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `purchase_number` (`purchase_number`),
  ADD KEY `idx_purchases_number` (`purchase_number`),
  ADD KEY `idx_purchases_date` (`purchase_date`),
  ADD KEY `idx_purchases_status` (`status`),
  ADD KEY `supplier_id` (`supplier_id`);

--
-- Indexes for table `purchase_items`
--
ALTER TABLE `purchase_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_purchase_items_purchase` (`purchase_id`),
  ADD KEY `idx_purchase_items_product` (`product_id`);

--
-- Indexes for table `purchase_returns`
--
ALTER TABLE `purchase_returns`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `return_number` (`return_number`),
  ADD KEY `idx_purchase_returns_number` (`return_number`),
  ADD KEY `idx_purchase_returns_receiving` (`receiving_id`),
  ADD KEY `idx_purchase_returns_purchase` (`purchase_id`),
  ADD KEY `idx_purchase_returns_date` (`return_date`),
  ADD KEY `idx_purchase_returns_status` (`status`),
  ADD KEY `supplier_id` (`supplier_id`);

--
-- Indexes for table `purchase_return_items`
--
ALTER TABLE `purchase_return_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_purchase_return_items_return` (`return_id`),
  ADD KEY `idx_purchase_return_items_product` (`product_id`),
  ADD KEY `receiving_item_id` (`receiving_item_id`);

--
-- Indexes for table `receivings`
--
ALTER TABLE `receivings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `receiving_number` (`receiving_number`),
  ADD KEY `idx_receivings_number` (`receiving_number`),
  ADD KEY `idx_receivings_purchase` (`purchase_id`),
  ADD KEY `idx_receivings_date` (`receiving_date`),
  ADD KEY `idx_receivings_status` (`status`),
  ADD KEY `supplier_id` (`supplier_id`);

--
-- Indexes for table `receiving_items`
--
ALTER TABLE `receiving_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_receiving_items_receiving` (`receiving_id`),
  ADD KEY `idx_receiving_items_product` (`product_id`);

--
-- Indexes for table `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`setting_key`);

--
-- Indexes for table `stock_movements`
--
ALTER TABLE `stock_movements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_stock_movements_product` (`product_id`),
  ADD KEY `idx_stock_movements_date` (`created_at`),
  ADD KEY `idx_stock_movements_type` (`type`);

--
-- Indexes for table `suppliers`
--
ALTER TABLE `suppliers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `idx_suppliers_code` (`code`),
  ADD KEY `idx_suppliers_name` (`name`);

--
-- Indexes for table `sync_queue`
--
ALTER TABLE `sync_queue`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_sync_queue_status` (`status`),
  ADD KEY `idx_sync_queue_table` (`table_name`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `transaction_number` (`transaction_number`),
  ADD KEY `idx_transactions_number` (`transaction_number`),
  ADD KEY `idx_transactions_date` (`transaction_date`),
  ADD KEY `idx_transactions_status` (`status`),
  ADD KEY `idx_transactions_sync` (`sync_status`);

--
-- Indexes for table `transaction_items`
--
ALTER TABLE `transaction_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_transaction_items_transaction` (`transaction_id`),
  ADD KEY `idx_transaction_items_product` (`product_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_users_username` (`username`),
  ADD KEY `idx_users_role` (`role`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `sync_queue`
--
ALTER TABLE `sync_queue`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `pending_transaction_items`
--
ALTER TABLE `pending_transaction_items`
  ADD CONSTRAINT `pending_transaction_items_ibfk_1` FOREIGN KEY (`pending_id`) REFERENCES `pending_transactions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `purchases`
--
ALTER TABLE `purchases`
  ADD CONSTRAINT `purchases_ibfk_1` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `purchase_items`
--
ALTER TABLE `purchase_items`
  ADD CONSTRAINT `purchase_items_ibfk_1` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `purchase_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE RESTRICT;

--
-- Constraints for table `purchase_returns`
--
ALTER TABLE `purchase_returns`
  ADD CONSTRAINT `purchase_returns_ibfk_1` FOREIGN KEY (`receiving_id`) REFERENCES `receivings` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `purchase_returns_ibfk_2` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `purchase_returns_ibfk_3` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `purchase_return_items`
--
ALTER TABLE `purchase_return_items`
  ADD CONSTRAINT `purchase_return_items_ibfk_1` FOREIGN KEY (`return_id`) REFERENCES `purchase_returns` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `purchase_return_items_ibfk_2` FOREIGN KEY (`receiving_item_id`) REFERENCES `receiving_items` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `purchase_return_items_ibfk_3` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE RESTRICT;

--
-- Constraints for table `receivings`
--
ALTER TABLE `receivings`
  ADD CONSTRAINT `receivings_ibfk_1` FOREIGN KEY (`purchase_id`) REFERENCES `purchases` (`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `receivings_ibfk_2` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `receiving_items`
--
ALTER TABLE `receiving_items`
  ADD CONSTRAINT `receiving_items_ibfk_1` FOREIGN KEY (`receiving_id`) REFERENCES `receivings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `receiving_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE RESTRICT;

--
-- Constraints for table `stock_movements`
--
ALTER TABLE `stock_movements`
  ADD CONSTRAINT `stock_movements_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `transaction_items`
--
ALTER TABLE `transaction_items`
  ADD CONSTRAINT `transaction_items_ibfk_1` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `transaction_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE RESTRICT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
