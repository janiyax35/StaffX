-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE user_role AS ENUM ('admin', 'owner', 'driver', 'staff');
CREATE TYPE subscription_tier AS ENUM ('free', 'growth', 'fleet');
CREATE TYPE payment_status AS ENUM ('paid', 'unpaid');

-- Profiles Table
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  role user_role NOT NULL DEFAULT 'staff',
  is_driver BOOLEAN DEFAULT FALSE,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Buses Table
CREATE TABLE buses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES profiles(id) NOT NULL,
  plate_number TEXT NOT NULL,
  capacity INT NOT NULL,
  model TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bus Drivers Table
CREATE TABLE bus_drivers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  bus_id UUID REFERENCES buses(id) ON DELETE CASCADE NOT NULL,
  driver_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(bus_id, driver_id)
);

-- Routes Table
CREATE TABLE routes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  bus_id UUID REFERENCES buses(id) ON DELETE CASCADE NOT NULL,
  morning_route JSONB, -- Array of stops {lat, lng, name, time}
  evening_route JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subscriptions Table
CREATE TABLE subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES profiles(id) NOT NULL,
  tier_level subscription_tier DEFAULT 'free',
  expiry_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trip Overrides Table
CREATE TABLE trip_overrides (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID REFERENCES profiles(id) NOT NULL,
  temp_bus_id UUID REFERENCES buses(id) NOT NULL,
  valid_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment Ledger Table
CREATE TABLE payment_ledger (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID REFERENCES profiles(id) NOT NULL,
  owner_id UUID REFERENCES profiles(id) NOT NULL,
  month DATE NOT NULL, -- e.g., '2023-10-01' for October
  amount DECIMAL(10, 2) NOT NULL,
  status payment_status DEFAULT 'unpaid',
  payment_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Announcements Table
CREATE TABLE announcements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  bus_id UUID REFERENCES buses(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

-- Policies

-- Profiles:
-- Public profiles are viewable by everyone (needed for drivers/owners to see each other)
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
-- Users can update own profile
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Buses:
-- Viewable by everyone (simplified for Phase 1)
CREATE POLICY "Buses are viewable by everyone" ON buses FOR SELECT USING (true);
-- Owners can insert buses (Trigger will enforce limit)
CREATE POLICY "Owners can insert buses" ON buses FOR INSERT WITH CHECK (auth.uid() = owner_id);
-- Owners can update own buses
CREATE POLICY "Owners can update own buses" ON buses FOR UPDATE USING (auth.uid() = owner_id);
-- Owners can delete own buses
CREATE POLICY "Owners can delete own buses" ON buses FOR DELETE USING (auth.uid() = owner_id);

-- Subscriptions:
-- Viewable by owner
CREATE POLICY "Owners can view own subscription" ON subscriptions FOR SELECT USING (auth.uid() = owner_id);
-- Only admins/system should insert/update subscriptions (Manual override or RevenueCat hook).
-- For now, allow owner to read.

-- Bus Drivers:
-- Owners can manage drivers for their buses
CREATE POLICY "Owners can manage drivers" ON bus_drivers FOR ALL USING (
  EXISTS (SELECT 1 FROM buses WHERE buses.id = bus_drivers.bus_id AND buses.owner_id = auth.uid())
);
-- Drivers can view their assignments
CREATE POLICY "Drivers can view assignments" ON bus_drivers FOR SELECT USING (auth.uid() = driver_id);

-- Routes:
-- Visible to everyone (simplification)
CREATE POLICY "Routes viewable by everyone" ON routes FOR SELECT USING (true);
-- Manageable by Owner and Driver of the bus
CREATE POLICY "Owners can manage routes" ON routes FOR ALL USING (
  EXISTS (SELECT 1 FROM buses WHERE buses.id = routes.bus_id AND buses.owner_id = auth.uid())
);
-- Drivers can update routes? Maybe just view for now.

-- Trigger for Subscription Enforcement
CREATE OR REPLACE FUNCTION check_bus_limit()
RETURNS TRIGGER AS $$
DECLARE
  current_count INT;
  sub_tier subscription_tier;
  limit_count INT;
BEGIN
  -- Get current bus count for owner
  SELECT COUNT(*) INTO current_count FROM buses WHERE owner_id = NEW.owner_id;

  -- Get subscription tier
  SELECT tier_level INTO sub_tier FROM subscriptions WHERE owner_id = NEW.owner_id;

  -- Default to free if no subscription found
  IF sub_tier IS NULL THEN
    sub_tier := 'free';
  END IF;

  -- Set limit based on tier
  IF sub_tier = 'free' THEN
    limit_count := 1;
  ELSIF sub_tier = 'growth' THEN
    limit_count := 2;
  ELSE
    limit_count := 9999; -- Fleet
  END IF;

  IF current_count >= limit_count THEN
    RAISE EXCEPTION 'Bus limit reached for your subscription tier.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_bus_limit
BEFORE INSERT ON buses
FOR EACH ROW
EXECUTE FUNCTION check_bus_limit();

-- Function to handle new user signup (auto-create profile)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', (new.raw_user_meta_data->>'role')::user_role);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger the function every time a user is created
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
