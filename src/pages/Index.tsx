import { useAuth } from "@/hooks/useAuth";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Link } from "react-router-dom";
import { Utensils, User, LogOut } from "lucide-react";

const Index = () => {
  const { user, loading, signOut } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-muted-foreground">Loading...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background px-4">
        <div className="text-center max-w-2xl">
          <div className="flex items-center justify-center mb-8">
            <Utensils className="h-12 w-12 text-primary mr-3" />
            <h1 className="text-5xl font-bold text-foreground">UniFood</h1>
          </div>
          <h2 className="text-3xl font-semibold mb-4 text-foreground">
            University Food Ordering Made Simple
          </h2>
          <p className="text-xl text-muted-foreground mb-8">
            Order from your favorite campus canteens, skip the queues, and enjoy fresh meals delivered right to you.
          </p>
          <Card className="max-w-md mx-auto">
            <CardHeader>
              <CardTitle>Get Started</CardTitle>
              <CardDescription>
                Sign in to start ordering from your campus canteens
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Link to="/auth">
                <Button className="w-full" size="lg">
                  Sign In / Sign Up
                </Button>
              </Link>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center">
            <Utensils className="h-8 w-8 text-primary mr-2" />
            <h1 className="text-2xl font-bold text-foreground">UniFood</h1>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <User className="h-4 w-4" />
              <span>{user.email}</span>
            </div>
            <Button variant="outline" size="sm" onClick={signOut}>
              <LogOut className="h-4 w-4 mr-2" />
              Sign Out
            </Button>
          </div>
        </div>
      </header>
      
      <main className="container mx-auto px-4 py-8">
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold mb-4 text-foreground">
            Welcome back!
          </h2>
          <p className="text-xl text-muted-foreground">
            Choose from available canteens and start ordering
          </p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <Card>
            <CardHeader>
              <CardTitle>Browse Canteens</CardTitle>
              <CardDescription>
                Explore all available campus dining options
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button className="w-full">View Canteens</Button>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader>
              <CardTitle>Your Orders</CardTitle>
              <CardDescription>
                Track your current and past orders
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button variant="outline" className="w-full">View Orders</Button>
            </CardContent>
          </Card>
          
          <Card>
            <CardHeader>
              <CardTitle>Profile</CardTitle>
              <CardDescription>
                Manage your account and preferences
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button variant="outline" className="w-full">Edit Profile</Button>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  );
};

export default Index;
