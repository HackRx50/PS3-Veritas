import React, { useContext, useState, useEffect } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "../../firebase";
import './login.scss';
import { Link, useNavigate } from 'react-router-dom';
import { AuthContext } from "../context/AuthContext";

const Login = () => {
  const [error, setError] = useState('');
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const navigate = useNavigate();

  const { setCurrentUser } = useContext(AuthContext);

  useEffect(() => {
    // Clear form fields on component mount
    setEmail("");
    setPassword("");
  }, []);

  const handleLogin = async (e) => {
    e.preventDefault();

    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;
      localStorage.setItem("userMail", email);
      setCurrentUser(user);
      navigate('/main');
    } catch (error) {
      console.error("Login failed:", error);
      setError(true);
      handleFirebaseError(error);
    }
  };

  const handleFirebaseError = (error) => {
    const errorCode = error.code;
    switch (errorCode) {
      case 'auth/user-not-found':
        setError('No user found with this email.');
        break;
      case 'auth/wrong-password':
        setError('Incorrect password.');
        break;
      case 'auth/invalid-email':
        setError('Invalid email format.');
        break;
      case 'auth/user-disabled':
        setError('User account is disabled.');
        break;
      default:
        setError('Login failed. Please try again.');
    }
  };

  return (
    <div className="login-page">
      <div className="login-container">
        <div className="login-box">
          <h1 className="title">ClaimSafe</h1>
          <h2 className="subtitle">Login</h2>
          <form onSubmit={handleLogin} autoComplete="off">
            <div className="input-group">
              <label htmlFor="email">Email</label>
              <input
                type="email"
                id="email"
                name="email"
                placeholder="username@gmail.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="new-email"
              />
            </div>
            <div className="input-group">
              <label htmlFor="password">Password</label>
              <input
                className="passwords"
                type="password"
                id="password"
                name="password"
                placeholder="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="new-password"
              />
            </div>
            <button className="login-button" type="submit">Login</button>
            {error && <span className="error-message">{error}</span>}
          </form>
         
          <div className="register-link">
            Don't have an account yet? <Link to="/signup">Register for free</Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;