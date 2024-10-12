import './App.css';
import { BrowserRouter as Router, Route, Routes,Navigate, useLocation } from 'react-router-dom';
import Login from './components/login/login';
import Signup from './components/signup/signup';
import Main from './components/mainpage/main';
import History from './components/History/history';
import Verify from './components/signup/verify';
import { AuthProvider,AuthContext } from './components/context/AuthContext';
import { useContext } from 'react';

const RequireAuth = ({ children }) => {
  const { currentUser } = useContext(AuthContext);
  const location = useLocation();
  if (!currentUser) {
    return <Navigate to="/" state={{ from: location }} replace />;
  }

  return children;
};

function AppRoutes() {
  return (
    <Routes>
      {/* Public Routes */}
      <Route path="/" element={<Login />} />
      <Route path="/signup" element={<Signup />} />
      <Route path="/verify" element={<Verify />} />

      {/* Protected Routes */}
      <Route
        path="/main"
        element={
          <RequireAuth>
            <Main />
          </RequireAuth>
        }
      />
      <Route
        path="/history"
        element={
          <RequireAuth>
            <History />
          </RequireAuth>
        }
      />
    </Routes>
  );
}

function App() {
  return (
    <div className="App">
      <AuthProvider>
        <Router>
          <AppRoutes />
        </Router>
      </AuthProvider>
    </div>
  );
}

export default App;