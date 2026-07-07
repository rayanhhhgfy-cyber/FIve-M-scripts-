-- ==========================================================================
-- FiveM RP Server - Master Database Schema
-- Run this ONCE against your database
-- ==========================================================================

-- === CORE IDENTITY ===
ALTER TABLE players ADD COLUMN IF NOT EXISTS citizenid VARCHAR(20) UNIQUE;

CREATE TABLE IF NOT EXISTS cid_registry (
  id INT AUTO_INCREMENT PRIMARY KEY,
  license VARCHAR(60) NOT NULL,
  citizenid VARCHAR(20) NOT NULL UNIQUE,
  slot INT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_license (license),
  INDEX idx_citizenid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS id_card_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  action VARCHAR(50) NOT NULL,
  data JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === COMMUNICATIONS ===
CREATE TABLE IF NOT EXISTS phone_tweets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  content TEXT NOT NULL,
  image_url VARCHAR(255),
  likes INT DEFAULT 0,
  retweets INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_citizenid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_tweet_likes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tweet_id INT NOT NULL,
  citizenid VARCHAR(20) NOT NULL,
  UNIQUE KEY uk_tweet_like (tweet_id, citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_tweet_comments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tweet_id INT NOT NULL,
  citizenid VARCHAR(20) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS blackchat_room_members (
  id INT AUTO_INCREMENT PRIMARY KEY,
  room_id VARCHAR(64) NOT NULL,
  citizenid VARCHAR(20) NOT NULL,
  role VARCHAR(20) DEFAULT 'member',
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_bcrm_member (room_id, citizenid),
  INDEX idx_bcrm_room (room_id),
  INDEX idx_bcrm_cid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS blackchat_rooms (
  id INT AUTO_INCREMENT PRIMARY KEY,
  room_id VARCHAR(64) NOT NULL UNIQUE,
  display_name VARCHAR(100) DEFAULT NULL,
  created_by VARCHAR(20) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_bcr_room (room_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS blackchat_messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sender_cid VARCHAR(20) NOT NULL,
  receiver_cid VARCHAR(20),
  room_id VARCHAR(64),
  content TEXT NOT NULL,
  coords JSON,
  self_destruct_after INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_room (room_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === ROSTERS ===
CREATE TABLE IF NOT EXISTS job_rosters (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL UNIQUE,
  job VARCHAR(50) NOT NULL,
  grade INT DEFAULT 0,
  hired_by VARCHAR(20),
  hired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS job_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(20) NOT NULL,
  target_cid VARCHAR(20) NOT NULL,
  performed_by VARCHAR(20) NOT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS gang_rosters (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL UNIQUE,
  gang VARCHAR(50) NOT NULL,
  rank INT DEFAULT 0,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS mechanic_rosters LIKE job_rosters;

CREATE TABLE IF NOT EXISTS mechanic_invoices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  customer VARCHAR(20) NOT NULL,
  mechanic VARCHAR(20) NOT NULL,
  items JSON NOT NULL,
  total INT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === ADVANCED MECHANICS ===
ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS component_damage JSON;
ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS odometer INT DEFAULT 0;
ALTER TABLE player_vehicles ADD COLUMN IF NOT EXISTS last_parked TIMESTAMP NULL;

-- === LEGAL ===
CREATE TABLE IF NOT EXISTS court_cases (
  id INT AUTO_INCREMENT PRIMARY KEY,
  plaintiff VARCHAR(20), defendant VARCHAR(20), charges TEXT,
  status VARCHAR(20), trial_date DATETIME,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS retainer_contracts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  lawyer_cid VARCHAR(20), client_cid VARCHAR(20), fee INT,
  contingency DECIMAL(5,2), is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS seized_auctions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  vehicle_plate VARCHAR(20), property_id VARCHAR(50),
  current_bid INT DEFAULT 0, bidder VARCHAR(20), ends_at DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS business_licenses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  business VARCHAR(50), owner VARCHAR(20),
  active BOOLEAN DEFAULT TRUE, renewal_date DATE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ballistic_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  casing_serial VARCHAR(50), weapon_serial VARCHAR(50),
  citizenid VARCHAR(20), incident_coords JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS bail_bonds (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20), amount INT, posted_by VARCHAR(20),
  expires_at DATETIME, forfeited BOOLEAN DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS criminal_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20), offense TEXT, fine INT,
  prison_time INT, officer VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tax_config (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sales_tax DECIMAL(5,2) DEFAULT 8.00,
  property_tax DECIMAL(5,2) DEFAULT 1.50,
  updated_by VARCHAR(20), updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO tax_config (id, sales_tax, property_tax) VALUES (1, 8.00, 1.50);

CREATE TABLE IF NOT EXISTS flagged_transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  from_cid VARCHAR(20), to_cid VARCHAR(20), amount INT,
  flagged BOOLEAN DEFAULT FALSE, reviewed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === CRIME ===
CREATE TABLE IF NOT EXISTS smuggling_events (
  id INT AUTO_INCREMENT PRIMARY KEY,
  zone VARCHAR(50), status VARCHAR(20),
  drops_at TIMESTAMP, claimed_by VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS mobile_labs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  owner VARCHAR(20), vehicle_plate VARCHAR(20),
  product VARCHAR(50), quantity INT, stability INT DEFAULT 100, coords JSON
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS front_businesses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20), business VARCHAR(50),
  dirty_money INT DEFAULT 0, clean_rate DECIMAL(5,2) DEFAULT 0.1,
  last_payout TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS surveillance_cams (
  id INT AUTO_INCREMENT PRIMARY KEY,
  owner VARCHAR(20), coords JSON, heading DECIMAL(10,2),
  stream_url VARCHAR(255), is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS atm_skimmers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  atm_coords JSON, owner VARCHAR(20),
  stolen_total INT DEFAULT 0, installed_at TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS gang_renown (
  id INT AUTO_INCREMENT PRIMARY KEY,
  gang VARCHAR(50), level INT DEFAULT 1, xp INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS black_market_listings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  seller VARCHAR(20), item VARCHAR(50),
  price INT, is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS prison_escape_progress (
  id INT AUTO_INCREMENT PRIMARY KEY,
  power_down BOOLEAN DEFAULT FALSE, gate_destroyed BOOLEAN DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === EMS ===
CREATE TABLE IF NOT EXISTS autopsy_reports (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20), time_of_death DATETIME,
  weapon_used VARCHAR(50), angle DECIMAL(10,2), conducted_by VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS addiction_trackers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20), substance VARCHAR(50),
  dependency INT DEFAULT 0, last_dose TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS blood_bank (
  id INT AUTO_INCREMENT PRIMARY KEY,
  donor VARCHAR(20), blood_type VARCHAR(3),
  units INT DEFAULT 1, collected_at TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS field_medical_kits (
  id INT AUTO_INCREMENT PRIMARY KEY,
  owner VARCHAR(20), items JSON, coords JSON,
  is_deployed BOOLEAN DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === FLEET ===
CREATE TABLE IF NOT EXISTS vehicle_listings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20), plate VARCHAR(20), price INT,
  coords JSON, is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vehicle_component_tracker (
  id INT AUTO_INCREMENT PRIMARY KEY,
  plate VARCHAR(20), component VARCHAR(50), health INT DEFAULT 100
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS fleet_garage_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  plate VARCHAR(20), citizenid VARCHAR(20), odometer INT,
  entered_at TIMESTAMP, left_at TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === ECONOMY ===
CREATE TABLE IF NOT EXISTS stock_portfolio (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20), business VARCHAR(50),
  shares INT, purchased_at TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS auto_invoices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20), amount INT, reason TEXT,
  due_at DATETIME, paid BOOLEAN DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vault_boxes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  renter VARCHAR(20), items JSON, expires_at DATE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS insurance_policies (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20), provider VARCHAR(20),
  premium INT, coverage DECIMAL(5,2), is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === SOCIAL ===
CREATE TABLE IF NOT EXISTS instashot_profiles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) UNIQUE, username VARCHAR(50),
  followers INT DEFAULT 0, following INT DEFAULT 0, fame INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS instashot_posts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20), image_url VARCHAR(255), caption TEXT,
  likes INT DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS racing_events (
  id INT AUTO_INCREMENT PRIMARY KEY,
  organizer VARCHAR(20), track JSON, prize_pool INT,
  status VARCHAR(20), started_at TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS parcel_deliveries (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sender VARCHAR(20), receiver VARCHAR(20), items JSON,
  status VARCHAR(20), created_at TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === POLICE VEHICLE LOGS ===
CREATE TABLE IF NOT EXISTS police_vehicle_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20), vehicle VARCHAR(50), plate VARCHAR(20),
  action VARCHAR(20), timestamp INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === CRIME CENTER ===
CREATE TABLE IF NOT EXISTS emergency_calls (
  id INT AUTO_INCREMENT PRIMARY KEY,
  caller_cid VARCHAR(20), type VARCHAR(50), description TEXT,
  coords JSON, status VARCHAR(20) DEFAULT 'Active',
  assigned_unit VARCHAR(20), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS panic_alerts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20), alert_type VARCHAR(50), label VARCHAR(100),
  coords_x DOUBLE, coords_y DOUBLE, coords_z DOUBLE,
  timestamp INT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS lpr_hits (
  id INT AUTO_INCREMENT PRIMARY KEY,
  plate VARCHAR(20), coords JSON, officer_cid VARCHAR(20),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === K-9 UNIT ===
CREATE TABLE IF NOT EXISTS k9_units (
  id INT AUTO_INCREMENT PRIMARY KEY,
  call_sign VARCHAR(20), breed VARCHAR(50), specialization VARCHAR(50),
  handler_cid VARCHAR(20), status VARCHAR(20) DEFAULT 'Active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS k9_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  unit_id INT, action VARCHAR(50), handler_cid VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === PASSCODE DOORS ===
CREATE TABLE IF NOT EXISTS passcode_doors (
  id INT AUTO_INCREMENT PRIMARY KEY,
  label VARCHAR(100) DEFAULT 'Passcode Door',
  door_model INT NOT NULL,
  coords JSON NOT NULL,
  heading FLOAT DEFAULT 0,
  passcode_hash VARCHAR(64) NOT NULL,
  maker_cid VARCHAR(20) NOT NULL,
  is_locked TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS passcode_door_access (
  id INT AUTO_INCREMENT PRIMARY KEY,
  door_id INT NOT NULL,
  citizenid VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_passcode_door_access_door (door_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS passcode_door_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  door_id INT NOT NULL,
  citizenid VARCHAR(20) NOT NULL,
  action VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_door_logs_door (door_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === GOD ADMIN OWNERS ===
CREATE TABLE IF NOT EXISTS server_owners (
  id INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(100) NOT NULL UNIQUE,
  group_name VARCHAR(20) DEFAULT 'god',
  granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_so_identifier (identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === ADMIN LOGS ===
CREATE TABLE IF NOT EXISTS admin_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  admin_cid VARCHAR(20) NOT NULL,
  action VARCHAR(100) NOT NULL,
  target VARCHAR(255) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_admin_logs_admin (admin_cid),
  INDEX idx_admin_logs_action (action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === FIB DOORS ([shared]/fib-building) ===
CREATE TABLE IF NOT EXISTS fib_doors (
  door_name VARCHAR(64) NOT NULL PRIMARY KEY,
  is_locked TINYINT(1) DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === CID GRADE CONFIG ([cid]/cid-terminal) ===
CREATE TABLE IF NOT EXISTS cid_grade_config (
  grade INT NOT NULL PRIMARY KEY,
  label VARCHAR(100) NOT NULL,
  salary INT DEFAULT 500
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === CID ARMORY ITEMS ([cid]/cid-terminal) ===
CREATE TABLE IF NOT EXISTS cid_armory_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  item_name VARCHAR(64) NOT NULL UNIQUE,
  label VARCHAR(100) NOT NULL,
  rank INT DEFAULT 0,
  price INT DEFAULT 0,
  category VARCHAR(50) DEFAULT 'general',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_cai_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === CID CASES ([cid]/cid-terminal) ===
CREATE TABLE IF NOT EXISTS cid_cases (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  assigned_to VARCHAR(20) DEFAULT NULL,
  status VARCHAR(20) DEFAULT 'open',
  created_by VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  closed_at TIMESTAMP NULL,
  INDEX idx_cc_status (status),
  INDEX idx_cc_assigned (assigned_to)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === CID WARRANTS ([cid]/cid-terminal) ===
CREATE TABLE IF NOT EXISTS cid_warrants (
  id INT AUTO_INCREMENT PRIMARY KEY,
  target_name VARCHAR(100) DEFAULT NULL,
  target_cid VARCHAR(20) DEFAULT NULL,
  crime VARCHAR(200) DEFAULT NULL,
  issued_by VARCHAR(20) NOT NULL,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_cw_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === CID BOLOS ([cid]/cid-terminal) ===
CREATE TABLE IF NOT EXISTS cid_bolos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  type VARCHAR(20) DEFAULT 'person',
  plate VARCHAR(20) DEFAULT NULL,
  description TEXT,
  reason VARCHAR(200) DEFAULT NULL,
  issued_by VARCHAR(20) NOT NULL,
  active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_cb_active (active),
  INDEX idx_cb_type (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === CID PERSON NOTES ([cid]/cid-terminal) ===
CREATE TABLE IF NOT EXISTS cid_person_notes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  target_cid VARCHAR(20) NOT NULL,
  note TEXT NOT NULL,
  flagged_by VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_cpn_target (target_cid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === VEHICLE SPAWN LOG ([cid]/cid-terminal) ===
CREATE TABLE IF NOT EXISTS vehicle_spawn_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  spawner_cid VARCHAR(20) NOT NULL,
  spawner_name VARCHAR(100) DEFAULT NULL,
  vehicle_model VARCHAR(50) NOT NULL,
  vehicle_label VARCHAR(100) DEFAULT NULL,
  spawned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_vsl_cid (spawner_cid),
  INDEX idx_vsl_model (vehicle_model)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === CID AUDIT LOG ([cid]/cid-terminal) ===
CREATE TABLE IF NOT EXISTS cid_audit_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(100) NOT NULL,
  target VARCHAR(255) DEFAULT NULL,
  performed_by_cid VARCHAR(20) NOT NULL,
  performed_by_name VARCHAR(100) DEFAULT NULL,
  details TEXT DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_cal_action (action),
  INDEX idx_cal_performer (performed_by_cid),
  INDEX idx_cal_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === WHITELIST ===
CREATE TABLE IF NOT EXISTS whitelist (
  id INT AUTO_INCREMENT PRIMARY KEY,
  license VARCHAR(60) NOT NULL UNIQUE,
  name VARCHAR(100) DEFAULT NULL,
  status ENUM('pending','approved','rejected') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_whitelist_license (license)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === REPORT LOGS ===
CREATE TABLE IF NOT EXISTS report_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  report_id INT NOT NULL,
  reporter_cid VARCHAR(20) DEFAULT NULL,
  handler_cid VARCHAR(20) DEFAULT NULL,
  reason TEXT,
  resolution TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === PROPERTY SYSTEM (player/property-system) ===
CREATE TABLE IF NOT EXISTS player_properties (
  id INT AUTO_INCREMENT PRIMARY KEY,
  property_id VARCHAR(50) NOT NULL,
  owner_cid VARCHAR(20) NOT NULL,
  owner_name VARCHAR(100) DEFAULT NULL,
  purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_property (property_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === ADVANCED HOUSING ([housing]/advanced-housing) ===
CREATE TABLE IF NOT EXISTS player_houses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  house_id VARCHAR(50) NOT NULL UNIQUE,
  owner_cid VARCHAR(20) NOT NULL,
  owner_name VARCHAR(100) DEFAULT NULL,
  purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS house_furniture (
  id INT AUTO_INCREMENT PRIMARY KEY,
  house_id VARCHAR(50) NOT NULL,
  furniture_id VARCHAR(50) NOT NULL,
  coords JSON NOT NULL,
  rotation JSON NOT NULL,
  INDEX idx_house_furn (house_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS house_guests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  house_id VARCHAR(50) NOT NULL,
  guest_cid VARCHAR(20) NOT NULL,
  guest_name VARCHAR(100) DEFAULT NULL,
  UNIQUE KEY uk_house_guest (house_id, guest_cid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS house_alarms (
  id INT AUTO_INCREMENT PRIMARY KEY,
  house_id VARCHAR(50) NOT NULL UNIQUE,
  active TINYINT(1) DEFAULT 0,
  level VARCHAR(20) DEFAULT 'basic',
  armed TINYINT(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS house_vehicles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  house_id VARCHAR(50) NOT NULL,
  plate VARCHAR(20) NOT NULL,
  model VARCHAR(50) DEFAULT NULL,
  stored_by VARCHAR(20) DEFAULT NULL,
  INDEX idx_house_veh (house_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === COURT SYSTEM ([civilian]/court-system) ===
ALTER TABLE court_cases ADD COLUMN IF NOT EXISTS prosecutor_cid VARCHAR(20) AFTER plaintiff;
ALTER TABLE court_cases ADD COLUMN IF NOT EXISTS defendant_cid VARCHAR(20) AFTER prosecutor_cid;
ALTER TABLE court_cases ADD COLUMN IF NOT EXISTS charge VARCHAR(100) AFTER defendant_cid;
ALTER TABLE court_cases ADD COLUMN IF NOT EXISTS judge_cid VARCHAR(20) AFTER charge;
ALTER TABLE court_cases ADD COLUMN IF NOT EXISTS bail_amount INT DEFAULT 0 AFTER status;
ALTER TABLE court_cases ADD COLUMN IF NOT EXISTS bail_paid TINYINT(1) DEFAULT 0 AFTER bail_amount;
ALTER TABLE court_cases ADD COLUMN IF NOT EXISTS verdict VARCHAR(20) AFTER bail_paid;
ALTER TABLE court_cases ADD COLUMN IF NOT EXISTS sentence_time INT DEFAULT 0 AFTER verdict;
ALTER TABLE court_cases ADD COLUMN IF NOT EXISTS sentence_fine INT DEFAULT 0 AFTER sentence_time;
ALTER TABLE court_cases ADD COLUMN IF NOT EXISTS case_id VARCHAR(20) UNIQUE AFTER id;
ALTER TABLE court_cases DROP COLUMN plaintiff;

CREATE TABLE IF NOT EXISTS court_evidence (
  id INT AUTO_INCREMENT PRIMARY KEY,
  case_id VARCHAR(20) NOT NULL,
  evidence_id INT NOT NULL,
  label VARCHAR(100) DEFAULT NULL,
  description TEXT,
  submitted_cid VARCHAR(20) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_court_ev (case_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS court_appeals (
  id INT AUTO_INCREMENT PRIMARY KEY,
  case_id VARCHAR(20) NOT NULL,
  appellant_cid VARCHAR(20) NOT NULL,
  reason TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === ADVANCED BANKING ([economy]/banking-plus) ===
CREATE TABLE IF NOT EXISTS bank_credit_scores (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL UNIQUE,
  score INT DEFAULT 600,
  INDEX idx_credit_cid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS bank_loans (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  loan_type VARCHAR(20) DEFAULT NULL,
  amount INT NOT NULL,
  interest INT DEFAULT 0,
  total_repayment INT DEFAULT 0,
  weekly_payment INT DEFAULT 0,
  remaining INT DEFAULT 0,
  term_days INT DEFAULT 30,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_loan_cid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS bank_investments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  invest_type VARCHAR(50) NOT NULL,
  amount INT NOT NULL,
  duration INT DEFAULT 7,
  status VARCHAR(20) DEFAULT 'active',
  payout INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_invest_cid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS bank_transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sender_cid VARCHAR(20) DEFAULT NULL,
  receiver_cid VARCHAR(20) DEFAULT NULL,
  amount INT NOT NULL,
  fee INT DEFAULT 0,
  type VARCHAR(50) DEFAULT 'transfer',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tx_sender (sender_cid),
  INDEX idx_tx_receiver (receiver_cid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === FOOD TRUCK ([business]/food-truck) ===
CREATE TABLE IF NOT EXISTS food_trucks (
  id INT AUTO_INCREMENT PRIMARY KEY,
  truck_id VARCHAR(50) NOT NULL UNIQUE,
  owner_cid VARCHAR(20) NOT NULL,
  owner_name VARCHAR(100) DEFAULT NULL,
  purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  passed_inspection TINYINT(1) DEFAULT 0,
  satisfaction DECIMAL(5,2) DEFAULT 100.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS food_truck_menu (
  id INT AUTO_INCREMENT PRIMARY KEY,
  truck_id VARCHAR(50) NOT NULL,
  menu_item_id VARCHAR(50) NOT NULL,
  price INT DEFAULT 0,
  available TINYINT(1) DEFAULT 1,
  INDEX idx_ft_menu (truck_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS food_truck_inventory (
  id INT AUTO_INCREMENT PRIMARY KEY,
  truck_id VARCHAR(50) NOT NULL,
  ingredient VARCHAR(50) NOT NULL,
  quantity INT DEFAULT 0,
  UNIQUE KEY uk_ft_inv (truck_id, ingredient)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS food_truck_orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  truck_id VARCHAR(50) NOT NULL,
  order_id VARCHAR(50) NOT NULL UNIQUE,
  customer_cid VARCHAR(20) DEFAULT NULL,
  item_id VARCHAR(50) DEFAULT NULL,
  total INT DEFAULT 0,
  status VARCHAR(20) DEFAULT 'completed',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === TAXI ([jobs]/taxi-system) ===
CREATE TABLE IF NOT EXISTS taxi_ratings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  driver_cid VARCHAR(20) NOT NULL,
  customer_cid VARCHAR(20) NOT NULL,
  fare_amount INT DEFAULT 0,
  rating INT DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_taxi_driver (driver_cid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === EMERGENCY ALERTS ([emergency]/advanced-alerts) ===
CREATE TABLE IF NOT EXISTS emergency_alerts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  alert_type VARCHAR(50) NOT NULL,
  title VARCHAR(200) DEFAULT NULL,
  message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS shelter_assignments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  shelter_id VARCHAR(50) NOT NULL,
  citizenid VARCHAR(20) NOT NULL,
  entered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_shelter (shelter_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === PRISON ([prison]/prison-system) ===
CREATE TABLE IF NOT EXISTS prison_inmates (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(100) DEFAULT NULL,
  sentence INT DEFAULT 0,
  remaining INT DEFAULT 0,
  jobs_done INT DEFAULT 0,
  contraband_found INT DEFAULT 0,
  entered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  released_at TIMESTAMP NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS prison_contraband (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  contraband_type VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS prison_breakout_attempts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  method VARCHAR(50) DEFAULT NULL,
  success TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === POLICE BOLOS ([police]/bolo-system) ===
CREATE TABLE IF NOT EXISTS police_bolos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  type VARCHAR(20) DEFAULT 'vehicle',
  title VARCHAR(200) DEFAULT NULL,
  description TEXT,
  plate VARCHAR(20) DEFAULT NULL,
  last_seen VARCHAR(200) DEFAULT NULL,
  creator_cid VARCHAR(20) DEFAULT NULL,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === PHONE APP ([core]/phone-app) ===
CREATE TABLE IF NOT EXISTS phone_contacts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  owner_cid VARCHAR(20) NOT NULL,
  name VARCHAR(100) NOT NULL,
  number VARCHAR(20) DEFAULT NULL,
  cid VARCHAR(20) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_phone_contacts_owner (owner_cid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sender_cid VARCHAR(20) NOT NULL,
  receiver_cid VARCHAR(20) NOT NULL,
  content TEXT NOT NULL,
  `read` TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_phone_msgs_sender (sender_cid),
  INDEX idx_phone_msgs_receiver (receiver_cid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_photos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  filename VARCHAR(200) DEFAULT NULL,
  image_data LONGTEXT DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_phone_photos_cid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === PHONE APP EXTENDED TABLES ===
ALTER TABLE characters ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20) DEFAULT NULL;

CREATE TABLE IF NOT EXISTS phone_notes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  title VARCHAR(200) DEFAULT 'Untitled',
  content TEXT,
  color VARCHAR(20) DEFAULT '#FFD60A',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_pn_cid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_calendar (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  event_date DATE NOT NULL,
  event_time VARCHAR(10) DEFAULT '12:00',
  color VARCHAR(20) DEFAULT '#007AFF',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_pcal_cid (citizenid),
  INDEX idx_pcal_date (event_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_call_history (
  id INT AUTO_INCREMENT PRIMARY KEY,
  caller_cid VARCHAR(20) NOT NULL,
  receiver_cid VARCHAR(20) NOT NULL,
  status VARCHAR(20) DEFAULT 'dialed',
  duration INT DEFAULT 0,
  called_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  answered_at TIMESTAMP NULL,
  INDEX idx_pch_caller (caller_cid),
  INDEX idx_pch_receiver (receiver_cid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_voicemails (
  id INT AUTO_INCREMENT PRIMARY KEY,
  target_cid VARCHAR(20) NOT NULL,
  caller_cid VARCHAR(20) NOT NULL,
  caller_name VARCHAR(100) DEFAULT 'Unknown',
  message TEXT,
  duration INT DEFAULT 0,
  `read` TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_pv_target (target_cid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_settings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL UNIQUE,
  silent_mode TINYINT(1) DEFAULT 0,
  notifications TINYINT(1) DEFAULT 1,
  vibration TINYINT(1) DEFAULT 1,
  wallpaper VARCHAR(100) DEFAULT 'dark',
  ringtone VARCHAR(50) DEFAULT 'default',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_ps_cid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === PHONE GROUPS ([phones]/iphone) ===
CREATE TABLE IF NOT EXISTS phone_groups (
  id INT AUTO_INCREMENT PRIMARY KEY,
  owner_cid VARCHAR(20) NOT NULL,
  name VARCHAR(100) NOT NULL,
  members JSON DEFAULT NULL,
  created_at INT DEFAULT 0,
  INDEX idx_pg_owner (owner_cid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === VEHICLE DEALERSHIP ([economy]/vehicle-dealership) ===
CREATE TABLE IF NOT EXISTS player_vehicles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  plate VARCHAR(20) NOT NULL UNIQUE,
  model VARCHAR(50) NOT NULL,
  model_data JSON DEFAULT NULL,
  garage VARCHAR(50) DEFAULT 'A',
  fuel INT DEFAULT 100,
  financed TINYINT(1) DEFAULT 0,
  finance_payments INT DEFAULT 0,
  finance_total INT DEFAULT 0,
  finance_weekly INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_pv_citizenid (citizenid),
  INDEX idx_pv_plate (plate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === IMPOUND SYSTEM ([player]/garage-system) ===
CREATE TABLE IF NOT EXISTS impounded_vehicles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  vehicle_plate VARCHAR(20) NOT NULL,
  citizenid VARCHAR(20) NOT NULL,
  impound_time INT NOT NULL,
  fee INT DEFAULT 0,
  reason VARCHAR(200) DEFAULT NULL,
  released TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_iv_plate (vehicle_plate),
  INDEX idx_iv_citizenid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === CHARACTER SYSTEM ([core]/character-system) ===
CREATE TABLE IF NOT EXISTS characters (
  id INT AUTO_INCREMENT PRIMARY KEY,
  license VARCHAR(60) NOT NULL,
  citizenid VARCHAR(20) NOT NULL UNIQUE,
  slot INT DEFAULT 1,
  firstname VARCHAR(50) NOT NULL,
  lastname VARCHAR(50) NOT NULL,
  gender VARCHAR(10) DEFAULT 'male',
  birthdate DATE DEFAULT NULL,
  cash INT DEFAULT 2000,
  bank INT DEFAULT 5000,
  played_hours INT DEFAULT 0,
  last_location JSON DEFAULT NULL,
  last_login TIMESTAMP NULL,
  last_seen TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_char_license (license),
  INDEX idx_char_citizenid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === PHONE APP EXTENSIONS ([phones]/iphone) ===
ALTER TABLE phone_tweets ADD COLUMN IF NOT EXISTS name VARCHAR(100) DEFAULT 'Unknown';

CREATE TABLE IF NOT EXISTS phone_tiktok_videos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  name VARCHAR(100) DEFAULT 'Unknown',
  video_data LONGTEXT,
  description VARCHAR(255),
  likes INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tv_citizenid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_tiktok_likes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  video_id INT NOT NULL,
  citizenid VARCHAR(20) NOT NULL,
  UNIQUE KEY uk_tiktok_like (video_id, citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_restaurants (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  delivery_time VARCHAR(50) DEFAULT '30-45',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_restaurant_menu (
  id INT AUTO_INCREMENT PRIMARY KEY,
  restaurant_id INT NOT NULL,
  item_name VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  category VARCHAR(50) DEFAULT 'Main',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_rm_restaurant (restaurant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_delivery_orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  restaurant_id INT NOT NULL,
  items JSON,
  total DECIMAL(10,2) NOT NULL DEFAULT 0,
  status VARCHAR(20) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_do_citizenid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS phone_gigs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  poster_cid VARCHAR(20) NOT NULL,
  title VARCHAR(100) NOT NULL,
  description TEXT,
  reward DECIMAL(10,2) NOT NULL DEFAULT 0,
  location_x FLOAT DEFAULT 0,
  location_y FLOAT DEFAULT 0,
  location_z FLOAT DEFAULT 0,
  location_label VARCHAR(100) DEFAULT 'Unknown',
  status VARCHAR(20) DEFAULT 'open',
  worker_cid VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_pg_poster (poster_cid),
  INDEX idx_pg_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === CID TRACKERS ([cid]/undercover-vehicles / [cid]/surveillance-bugs) ===
CREATE TABLE IF NOT EXISTS cid_trackers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  plate VARCHAR(20) DEFAULT NULL,
  tracker_id VARCHAR(36) NOT NULL UNIQUE,
  placed_by VARCHAR(20) NOT NULL,
  placed_at INT NOT NULL,
  last_x DOUBLE DEFAULT 0,
  last_y DOUBLE DEFAULT 0,
  last_z DOUBLE DEFAULT 0,
  active BOOLEAN DEFAULT TRUE,
  INDEX idx_ct_plate (plate),
  INDEX idx_ct_tracker (tracker_id),
  INDEX idx_ct_active (active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cid_surveillance_bugs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  bug_type VARCHAR(20) NOT NULL,
  pos_x DOUBLE NOT NULL,
  pos_y DOUBLE NOT NULL,
  pos_z DOUBLE NOT NULL,
  heading DOUBLE DEFAULT 0,
  placed_by VARCHAR(20) NOT NULL,
  placed_at INT NOT NULL,
  expires_at INT NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  feed_data JSON DEFAULT NULL,
  INDEX idx_csb_type (bug_type),
  INDEX idx_csb_active (active),
  INDEX idx_csb_placer (placed_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === CID OPERATIONS ([cid]/operations-center) ===
CREATE TABLE IF NOT EXISTS cid_operations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  objectives TEXT,
  status VARCHAR(20) DEFAULT 'active',
  threat_level VARCHAR(20) DEFAULT 'medium',
  leader_cid VARCHAR(20) NOT NULL,
  members JSON DEFAULT NULL,
  timeline JSON DEFAULT NULL,
  report TEXT DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   INDEX idx_co_leader (leader_cid),
   INDEX idx_co_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === PAYROLL ([economy]/payroll) ===
CREATE TABLE IF NOT EXISTS payroll_config (
  `key` VARCHAR(64) NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO payroll_config (`key`, value) VALUES ('current_game_day', '0');

CREATE TABLE IF NOT EXISTS player_payrolls (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(50) NOT NULL UNIQUE,
  last_payday_game_day INT DEFAULT 0,
  last_paid_at TIMESTAMP NULL,
  INDEX idx_pp_citizenid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === BUNKER BUILDER ([admin]/bunker-builder) ===
CREATE TABLE IF NOT EXISTS custom_bunkers (
  id VARCHAR(64) PRIMARY KEY,
  label VARCHAR(128) NOT NULL,
  entrance_coords JSON NOT NULL,
  entrance_heading FLOAT DEFAULT 0,
  interior_name VARCHAR(64) NOT NULL,
  interior_coords JSON NOT NULL,
  interior_heading FLOAT DEFAULT 0,
  allowed_jobs JSON DEFAULT NULL,
  min_rank INT DEFAULT 0,
  vehicle_spawn JSON DEFAULT NULL,
  heli_spawn JSON DEFAULT NULL,
  rocks_json JSON DEFAULT NULL,
  roof_props_json JSON DEFAULT NULL,
  created_by VARCHAR(64) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === PLACE ANYWHERE ([admin]/place-anywhere) ===
CREATE TABLE IF NOT EXISTS placed_objects (
  id INT AUTO_INCREMENT PRIMARY KEY,
  model VARCHAR(64) NOT NULL,
  coords JSON NOT NULL,
  rotation JSON NOT NULL,
  admin_cid VARCHAR(64) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_po_admin (admin_cid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === PHONE WALLET ([phones]/iphone) ===
CREATE TABLE IF NOT EXISTS phone_wallet (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  card_type VARCHAR(50) NOT NULL,
  card_number VARCHAR(20) DEFAULT '****',
  holder_name VARCHAR(100) DEFAULT '',
  color VARCHAR(20) DEFAULT '#007AFF',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_pw_cid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === PHONE VIDEOS ([phones]/iphone) ===
CREATE TABLE IF NOT EXISTS phone_videos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  video_data LONGTEXT,
  thumbnail TEXT,
  filename VARCHAR(100) DEFAULT '',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_pv_cid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === ADMIN MANAGED DOORS ([admin]/god-menu) ===
CREATE TABLE IF NOT EXISTS admin_managed_doors (
  id INT AUTO_INCREMENT PRIMARY KEY,
  label VARCHAR(100) DEFAULT 'Door',
  door_model VARCHAR(50) DEFAULT '',
  coords JSON NOT NULL,
  heading FLOAT DEFAULT 0,
  lock_type VARCHAR(20) DEFAULT 'permanent',
  passcode_hash VARCHAR(64) DEFAULT NULL,
  allowed_jobs JSON DEFAULT NULL,
  is_locked TINYINT(1) DEFAULT 1,
  created_by VARCHAR(20) DEFAULT '',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_amd_type (lock_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === PLAYER NOTES ([player]/notepad) ===
CREATE TABLE IF NOT EXISTS player_notes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(20) NOT NULL,
  title VARCHAR(200) NOT NULL,
  content TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_pn_citizenid (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === ADMIN DYNAMIC ZONES ([admin]/admin-zones) ===
CREATE TABLE IF NOT EXISTS admin_zones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  zone_type VARCHAR(50) NOT NULL,
  coords JSON NOT NULL,
  radius FLOAT DEFAULT 2.0,
  allowed_jobs JSON DEFAULT NULL,
  min_grade INT DEFAULT 0,
  require_duty TINYINT(1) DEFAULT 0,
  is_active TINYINT(1) DEFAULT 1,
  created_by VARCHAR(50) DEFAULT '',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS admin_zone_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  zone_id INT NOT NULL,
  item_name VARCHAR(100) NOT NULL,
  label VARCHAR(100) NOT NULL,
  price INT DEFAULT 0,
  min_rank INT DEFAULT 0,
  currency VARCHAR(20) DEFAULT 'money',
  category VARCHAR(50) DEFAULT 'general',
  FOREIGN KEY (zone_id) REFERENCES admin_zones(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- === BANS ([admin]/god-menu) ===
CREATE TABLE IF NOT EXISTS bans (
  id INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(100) NOT NULL,
  player_name VARCHAR(100) DEFAULT NULL,
  reason TEXT DEFAULT NULL,
  banner VARCHAR(100) DEFAULT NULL,
  banner_cid VARCHAR(20) DEFAULT NULL,
  duration INT DEFAULT -1,
  banned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NULL DEFAULT NULL,
  INDEX idx_bans_id (identifier),
  INDEX idx_bans_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
