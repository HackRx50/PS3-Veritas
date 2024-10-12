import React, { useState } from 'react';
import { getAuth, createUserWithEmailAndPassword, sendEmailVerification } from 'firebase/auth';
import './signup.scss';
import { Link, useNavigate } from 'react-router-dom';

const Signup = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const navigate = useNavigate();

  const handleSignup = async (e) => {
    e.preventDefault();

    // Check if passwords match
    if (password !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    try {
      const auth = getAuth();
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // Send verification email
      await sendEmailVerification(user);

      setSuccess('Registration successful! Please check your email for verification.');
      setTimeout(() => navigate('/verify'), 3000); // Redirect to verification page
    } catch (error) {
      console.error("Signup failed:", error);
      handleFirebaseError(error);
    }
  };

  const handleFirebaseError = (error) => {
    const errorCode = error.code;
    switch (errorCode) {
      case 'auth/email-already-in-use':
        setError('This email is already in use.');
        break;
      case 'auth/invalid-email':
        setError('Invalid email format.');
        break;
      case 'auth/weak-password':
        setError('Password should be at least 6 characters.');
        break;
      case 'auth/network-request-failed':
        setError('Network error. Please check your connection.');
        break;
      default:
        setError('An unexpected error occurred. Please try again.');
    }
  };

  return (
    <div className="signup-page">
      <div className="signup-left">
        <div className="signup-left-content">
          <h1>ClaimSafe</h1>
          <h2>Verify your docs</h2>
          <p>
           Welcome to ClaimSafe, your trusted partner in document verification. With our advanced AI technology, you can easily verify the authenticity of your documents in seconds. Protect your information and ensure the integrity of your records with a simple, secure, and efficient verification process.
          </p>
        </div>
      </div>
      <div className="signup-right">
        <form className="signup-form" onSubmit={handleSignup}>
          <h3>Sign Up</h3>
          {error && <div className="errorr-message">{error}</div>}
          {success && <div className="success-message">{success}</div>}
          <div className="input-group">
            <label htmlFor="email">Email address</label>
            <input
              type="email"
              required
              placeholder="Enter your email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
          <div className="input-group">
            <label htmlFor="password">Password</label>
            <input
              type="password"
              required
              placeholder="Enter your password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>
          <div className="input-group">
            <label htmlFor="confirm-password">Confirm password</label>
            <input
              type="password"
              required
              placeholder="Re-Enter Password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
            />
          </div>
          <button type="submit" className="signup-button">Register</button>
          <p className="register-link">
            Already registered? <Link to="/">Login</Link>
          </p>
        </form>
      </div>
    </div>
  );
};

export default Signup;
