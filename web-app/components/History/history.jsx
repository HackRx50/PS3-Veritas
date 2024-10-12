import React, { useState, useEffect, useContext } from 'react';
import { Link, Navigate } from 'react-router-dom';
import { ref, get } from 'firebase/database';
import { database } from '../../firebase'; // Ensure this path is correct based on your project structure
import * as XLSX from 'xlsx'; // Import XLSX library
import { IoMdDownload } from "react-icons/io";
import { AuthContext } from '../context/AuthContext'; // Adjust path as needed
import './history.scss';

const History = () => {
  const { currentUser } = useContext(AuthContext);
  const [historyData, setHistoryData] = useState([]);

  useEffect(() => {
    if (currentUser) {
      const userId = currentUser.email.split('@')[0];
      const userRef = ref(database, `Output/${userId}`);
      get(userRef)
        .then((snapshot) => {
          if (snapshot.exists()) {
            const data = snapshot.val();
            const historyArray = Object.entries(data).map(([key, value]) => ({
              id: key,
              ...value,
            }));
            // Sort the history array in reverse chronological order
            historyArray.sort((a, b) => new Date(b.dateTime) - new Date(a.dateTime));
            setHistoryData(historyArray);
            console.log('Fetched and sorted history data:', historyArray);
          } else {
            console.log('No data available at the specified reference');
          }
        })
        .catch((error) => {
          console.error('Error fetching data from Firebase:', error);
        });
    }
  }, [currentUser]);

  // Function to download history data as an Excel file
  const downloadExcel = () => {
    // Define the headers
    const headers = ['file_name', 'is_forged', 'confidence'];

    // Prepare the data for Excel
    let excelData = historyData.map(record => {
      return {
        'file_name': record.imageName || 'N/A',
        'is_forged': record.statusMessage === 'Forged' ? 'TRUE' : 'FALSE',
        'confidence': record.confidenceScore != null ? `${record.confidenceScore.toFixed(2)}%` : 'N/A',
      };
    });

    // If there's no data, just use an empty array
    if (excelData.length === 0) {
      excelData = [{}]; // An empty object will result in a row with just the headers
    }

    // Create a worksheet
    const worksheet = XLSX.utils.json_to_sheet(excelData, { header: headers });

    // Create a workbook
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'History');

    // Generate Excel file
    XLSX.writeFile(workbook, `claimsafe_history_${currentUser.email.split('@')[0]}.xlsx`);
  };

 
  if (!currentUser) {
    return <Navigate to="/" />;
  }

  return (
    <div className="main-container">
      <header>
        <Link to="/main">
          <div className="logo">ClaimSafe</div>
        </Link>
       
        <button onClick={downloadExcel} className="download-btn"><span className="hidden-text">Report</span><IoMdDownload /></button>
        <nav>
          <Link to="/history">History</Link>
          <Link to="/">Log out</Link>
        </nav>
      </header>
      <div className="history">
        <div className="history-list">
          {historyData.length > 0 ? (
            <ul>
              {historyData.map((record) => {
                const confidenceScore = record.confidenceScore != null ? record.confidenceScore.toFixed(2) : 'N/A';
                const status = record.statusMessage || 'No status available';
                const imageName = record.imageName || 'N/A';
                const outputImage = record.outputImage ? `data:image/jpeg;base64,${record.outputImage}` : null;

                return (
                  <li key={record.id} className="history-item">
                    <div className="history-details">
                      {outputImage ? (
                        <img src={outputImage} alt="Analyzed Document" className="history-image" />
                      ) : (
                        <p>No output image available</p>
                      )}
                      <div className="history-sub-details">
                        <p><strong>File Name:</strong> {imageName}</p>
                        <p><strong>Confidence Score:</strong> {confidenceScore}%</p>
                        <p><strong>Status:</strong> {status}</p>
                        <p><strong>Date:</strong> {new Date(record.dateTime).toLocaleString()}</p>
                      </div>
                    </div>
                  </li>
                );
              })}
            </ul>
          ) : (
            <p>No history records found.</p>
          )}
        </div>
      </div>
    </div>
  );
};

export default History;