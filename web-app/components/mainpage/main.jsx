import React, { useState, useEffect, useContext } from 'react';
import { Link, Navigate } from 'react-router-dom';
import { ref, set, push} from 'firebase/database';
import { ref as storageRef, uploadBytes, getDownloadURL } from 'firebase/storage';
import { database, storage } from '../../firebase'; // Adjust path based on your project structure
import { AuthContext } from '../context/AuthContext'; // Adjust path as needed
import './main.scss';

const Main = () => {
  const { currentUser } = useContext(AuthContext);
  const [userId, setUserId] = useState('');
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [statusMessage, setStatusMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [confidenceScore, setConfidenceScore] = useState(null);
  const [outputImage, setOutputImage] = useState(null);

  useEffect(() => {
    if (currentUser) {
      const name = currentUser.email ? currentUser.email.split('@')[0] : '';
      setUserId(name);
    }
  }, [currentUser]);

  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImageFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setImagePreview(reader.result);
      };
      reader.readAsDataURL(file);
      setStatusMessage('');
      setConfidenceScore(null);
      // Don't clear the output image here
      // setOutputImage(null);
    }
  };

  const uploadImageToFirebase = async (file) => {
    const fileRef = storageRef(storage, `images/${userId}/${file.name}`);
    await uploadBytes(fileRef, file);
    const downloadURL = await getDownloadURL(fileRef);
    return downloadURL;
  };

  const callForgeryDetectionAPI = async (imageFile) => {
    setLoading(true);
    try {
      const formData = new FormData();
      formData.append('image', imageFile);

      const response = await fetch('http://10.19.10.78:5000/detect-forgery', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`API request failed with status ${response.status}: ${response.statusText}`);
      }

      const result = await response.json();
      if (result && typeof result.confidence === 'number' && typeof result.forgery_detected === 'boolean') {
        const status = result.forgery_detected ? 'Forged' : 'Authentic';
        setStatusMessage(status);
        setConfidenceScore(result.confidence * 100);
        setOutputImage(`data:image/jpeg;base64,${result.output_image}`);
        return { statusMessage: status, confidenceScore: result.confidence * 100, outputImage: result.output_image };
      } else {
        throw new Error('Invalid response from API');
      }
    } catch (error) {
      console.error('Error calling the API:', error);
      setStatusMessage('Failed to detect forgery. Please try again later.');
      setConfidenceScore(null);
      // Don't clear the output image on error
      // setOutputImage(null);
      return { statusMessage: 'Failed to detect forgery. Please try again later.', confidenceScore: null, outputImage: null };
    } finally {
      setLoading(false);
    }
  };

  const formatTimestamp = () => {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    const milliseconds = String(now.getMilliseconds()).padStart(6, '0');
    
    return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}.${milliseconds}`;
  };

  const saveDataToFirebase = async () => {
    if (!imageFile) {
      alert('Please upload an image before saving.');
      return;
    }

    try {
      setLoading(true);
      const imageURL = await uploadImageToFirebase(imageFile);

      const { statusMessage: apiStatusMessage, confidenceScore: apiConfidenceScore, outputImage: apiOutputImage } = await callForgeryDetectionAPI(imageFile);

      const dataRef = ref(database, `Output/${userId}`);
      const newEntryRef = push(dataRef);

      const formattedTimestamp = formatTimestamp();

      const data = {
        dateTime: formattedTimestamp,
        imageUrl: imageURL,
        imageName: imageFile.name,
        statusMessage: apiStatusMessage,
        confidenceScore: apiConfidenceScore,
        outputImage: apiOutputImage,
      };

      await set(newEntryRef, data);
      console.log('Data saved successfully!');

      setStatusMessage(apiStatusMessage);
      setConfidenceScore(apiConfidenceScore);
      if (apiOutputImage) {
        setOutputImage(`data:image/jpeg;base64,${apiOutputImage}`);
      }

    } catch (error) {
      console.error('Error saving data:', error);
      setStatusMessage('Error saving data. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const clearResults = () => {
    setImageFile(null);
    setImagePreview(null);
    setStatusMessage('');
    setConfidenceScore(null);
    setOutputImage(null);
  };

  if (!currentUser) {
    return <Navigate to="/" />;
  }

return (
    <div className="main-container">
      <header>
        <div className="logo">ClaimSafe</div>
        <nav className='nav-bar'>
          <Link to="/history">History</Link>
          <Link to="/">Log out</Link>
        </nav>
      </header>
      <h2 className="vyd">Verify your Document</h2>
      <div className="content">
        <div className="upload-section">
          <div className="file-upload">
            <div className="tabs">
              <p className="tab active">Upload</p>
            </div>
            <div className="seperate-lin"></div>
            <div className="file-drop">
              <p className="file-text">Click to browse or drag and drop your image</p>
              <input
                className='cf-button'
                type="file"
                accept="image/*"
                onChange={handleImageUpload}
              />
              <div>
                <button className='confirm-button' onClick={saveDataToFirebase}>Confirm</button>
                <button className='clear-button' onClick={clearResults}>Clear Results</button>
              </div>
            </div>
          </div>
        </div>
        <div className="status-section">
          {(outputImage || imagePreview) && (
            <div className="image-preview">
              <img src={outputImage || imagePreview} alt={outputImage ? "Analyzed Document" : "Uploaded Document"} />
            </div>
          )}
          {loading ? (
            <div className="loading-spinner"></div>
          ) : (
            <div className={`status-box ${
              statusMessage === 'Forged' ? 'danger' : 
              statusMessage === 'Authentic' ? 'success' : 
              'pending'}`}>
              {statusMessage ? (
                <>
                  <div>{statusMessage}</div>
                  <div>Confidence Score: {confidenceScore !== null ? `${confidenceScore.toFixed(2)}%` : 'N/A'}</div>
                </>
              ) : (
                imagePreview && 'Pending...'
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default Main;