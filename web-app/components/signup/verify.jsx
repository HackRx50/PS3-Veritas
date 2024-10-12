import React, { useEffect, useState } from 'react';
import { getAuth, sendEmailVerification, onAuthStateChanged } from 'firebase/auth';
import { useNavigate } from 'react-router-dom';
import './verify.scss'
const Verify = () => {
  const [user, setUser] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const auth = getAuth();
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      if (currentUser) {
        setUser(currentUser);
      } else {
        navigate('/');
      }
    });

    return () => unsubscribe();
  }, [navigate]);

  const sendVerifyLink = async () => {
    if (user && !user.emailVerified) {
      try {
        await sendEmailVerification(user);
        alert('A verification link has been sent to your email.');
      } catch (error) {
        console.error("Error sending verification email:", error);
        alert('Failed to send verification email. Please try again.');
      }
    }
  };

  const reload = async () => {
    if (user) {
      await user.reload();
      if (user.emailVerified) {
        navigate('/'); // Or wherever you want to redirect after verification
      } else {
        alert('Email not verified yet. Please check your email and click the verification link.');
      }
    }
  };

  if (!user) return null;

  return (
    <div className="verify-page">
        <h1>ClaimSafe</h1>
      <h2>Email Verification</h2>
      <p>Open your email and click on the link provided to verify your email address.</p>
      <button className='svl' onClick={sendVerifyLink}>Resend Verification Email</button>
      <button className='vme' onClick={reload}>I've Verified My Email</button>
    </div>
  );
};

export default Verify;