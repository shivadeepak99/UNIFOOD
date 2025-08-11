-- Create enum types
CREATE TYPE public.user_role AS ENUM ('student', 'canteen_manager', 'admin');
CREATE TYPE public.order_status AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled');

-- Create profiles table for user data
CREATE TABLE public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  role user_role NOT NULL DEFAULT 'student',
  student_id TEXT, -- for students
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create canteens table
CREATE TABLE public.canteens (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  location TEXT NOT NULL,
  manager_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  opening_hours JSONB, -- Store opening hours as JSON
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create menu categories table
CREATE TABLE public.menu_categories (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  canteen_id UUID NOT NULL REFERENCES public.canteens(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create menu items table
CREATE TABLE public.menu_items (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  category_id UUID NOT NULL REFERENCES public.menu_categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  image_url TEXT,
  is_available BOOLEAN NOT NULL DEFAULT true,
  preparation_time INTEGER, -- in minutes
  nutritional_info JSONB, -- Store nutritional information as JSON
  allergens TEXT[], -- Array of allergen information
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create orders table
CREATE TABLE public.orders (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  order_number TEXT NOT NULL UNIQUE,
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  canteen_id UUID NOT NULL REFERENCES public.canteens(id) ON DELETE CASCADE,
  status order_status NOT NULL DEFAULT 'pending',
  total_amount DECIMAL(10,2) NOT NULL,
  special_instructions TEXT,
  estimated_pickup_time TIMESTAMP WITH TIME ZONE,
  actual_pickup_time TIMESTAMP WITH TIME ZONE,
  token_number INTEGER,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create order items table
CREATE TABLE public.order_items (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  special_requests TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create feedback table
CREATE TABLE public.feedback (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  canteen_id UUID NOT NULL REFERENCES public.canteens(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.canteens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can view their own profile" ON public.profiles
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON public.profiles
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Canteen managers can view student profiles for orders" ON public.profiles
FOR SELECT USING (
  role = 'student' AND 
  EXISTS (
    SELECT 1 FROM public.profiles p 
    WHERE p.user_id = auth.uid() AND p.role = 'canteen_manager'
  )
);

-- RLS Policies for canteens
CREATE POLICY "Everyone can view active canteens" ON public.canteens
FOR SELECT USING (is_active = true);

CREATE POLICY "Canteen managers can manage their canteens" ON public.canteens
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    WHERE p.user_id = auth.uid() AND p.id = canteens.manager_id
  )
);

-- RLS Policies for menu categories
CREATE POLICY "Everyone can view active categories" ON public.menu_categories
FOR SELECT USING (is_active = true);

CREATE POLICY "Canteen managers can manage their categories" ON public.menu_categories
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.canteens c 
    JOIN public.profiles p ON c.manager_id = p.id
    WHERE c.id = menu_categories.canteen_id AND p.user_id = auth.uid()
  )
);

-- RLS Policies for menu items
CREATE POLICY "Everyone can view available items" ON public.menu_items
FOR SELECT USING (is_available = true);

CREATE POLICY "Canteen managers can manage their menu items" ON public.menu_items
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.menu_categories mc
    JOIN public.canteens c ON mc.canteen_id = c.id
    JOIN public.profiles p ON c.manager_id = p.id
    WHERE mc.id = menu_items.category_id AND p.user_id = auth.uid()
  )
);

-- RLS Policies for orders
CREATE POLICY "Students can view their own orders" ON public.orders
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    WHERE p.user_id = auth.uid() AND p.id = orders.student_id
  )
);

CREATE POLICY "Students can create their own orders" ON public.orders
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    WHERE p.user_id = auth.uid() AND p.id = orders.student_id AND p.role = 'student'
  )
);

CREATE POLICY "Canteen managers can view orders for their canteen" ON public.orders
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.canteens c 
    JOIN public.profiles p ON c.manager_id = p.id
    WHERE c.id = orders.canteen_id AND p.user_id = auth.uid()
  )
);

CREATE POLICY "Canteen managers can update orders for their canteen" ON public.orders
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.canteens c 
    JOIN public.profiles p ON c.manager_id = p.id
    WHERE c.id = orders.canteen_id AND p.user_id = auth.uid()
  )
);

-- RLS Policies for order items
CREATE POLICY "Students can view their order items" ON public.order_items
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.orders o 
    JOIN public.profiles p ON o.student_id = p.id
    WHERE o.id = order_items.order_id AND p.user_id = auth.uid()
  )
);

CREATE POLICY "Students can create order items for their orders" ON public.order_items
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.orders o 
    JOIN public.profiles p ON o.student_id = p.id
    WHERE o.id = order_items.order_id AND p.user_id = auth.uid()
  )
);

CREATE POLICY "Canteen managers can view order items for their canteen" ON public.order_items
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.orders o 
    JOIN public.canteens c ON o.canteen_id = c.id
    JOIN public.profiles p ON c.manager_id = p.id
    WHERE o.id = order_items.order_id AND p.user_id = auth.uid()
  )
);

-- RLS Policies for feedback
CREATE POLICY "Students can create feedback for their orders" ON public.feedback
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    WHERE p.user_id = auth.uid() AND p.id = feedback.student_id
  )
);

CREATE POLICY "Students can view their own feedback" ON public.feedback
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    WHERE p.user_id = auth.uid() AND p.id = feedback.student_id
  )
);

CREATE POLICY "Canteen managers can view feedback for their canteen" ON public.feedback
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.canteens c 
    JOIN public.profiles p ON c.manager_id = p.id
    WHERE c.id = feedback.canteen_id AND p.user_id = auth.uid()
  )
);

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_canteens_updated_at
BEFORE UPDATE ON public.canteens
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_menu_categories_updated_at
BEFORE UPDATE ON public.menu_categories
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_menu_items_updated_at
BEFORE UPDATE ON public.menu_items
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
BEFORE UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, full_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.email),
    NEW.email,
    COALESCE((NEW.raw_user_meta_data ->> 'role')::user_role, 'student')
  );
  RETURN NEW;
END;
$$;

-- Trigger to create profile when user signs up
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- Function to generate unique order numbers
CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  order_num TEXT;
  exists_check BOOLEAN;
BEGIN
  LOOP
    -- Generate order number: UF + YYYYMMDD + 4 random digits
    order_num := 'UF' || to_char(now(), 'YYYYMMDD') || LPAD(floor(random() * 10000)::text, 4, '0');
    
    -- Check if it already exists
    SELECT EXISTS(SELECT 1 FROM public.orders WHERE order_number = order_num) INTO exists_check;
    
    -- If it doesn't exist, break the loop
    IF NOT exists_check THEN
      EXIT;
    END IF;
  END LOOP;
  
  RETURN order_num;
END;
$$;

-- Function to auto-generate order number before insert
CREATE OR REPLACE FUNCTION public.set_order_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
    NEW.order_number := public.generate_order_number();
  END IF;
  RETURN NEW;
END;
$$;

-- Trigger to auto-generate order number
CREATE TRIGGER set_order_number_trigger
BEFORE INSERT ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.set_order_number();

-- Create indexes for better performance
CREATE INDEX idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_canteens_manager_id ON public.canteens(manager_id);
CREATE INDEX idx_menu_categories_canteen_id ON public.menu_categories(canteen_id);
CREATE INDEX idx_menu_items_category_id ON public.menu_items(category_id);
CREATE INDEX idx_orders_student_id ON public.orders(student_id);
CREATE INDEX idx_orders_canteen_id ON public.orders(canteen_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX idx_feedback_order_id ON public.feedback(order_id);
CREATE INDEX idx_feedback_canteen_id ON public.feedback(canteen_id);