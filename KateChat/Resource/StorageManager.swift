//
//  StorageManager.swift
//  KateChat
//
//  Created by KateFu on 2/11/23.
//

import Foundation
import FirebaseStorage

final class StorageManager{
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    public typealias UploadPictureCompletion = (Result<String, Error>)->Void
    
    public enum StorageErrors: Error{
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    /// upload picture to firebase storage, return completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion){
        storage.child("images/\(fileName)").putData(data, metadata: nil) { metadata, error in
            guard error == nil else{
                print("Failed to upload picture to firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else{
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
        
    }
    
    public func downloadUrl(for path: String, completion : @escaping (Result<URL, Error>)->Void){
        let reference = storage.child(path)
        reference.downloadURL(completion: {url, error in
            guard let url = url, error == nil else{
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
        })
    }
}
