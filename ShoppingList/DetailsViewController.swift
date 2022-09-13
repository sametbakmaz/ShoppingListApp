//
//  DetailsViewController.swift
//  ShoppingList
//
//  Created by Abdulsamet Bakmaz on 2.09.2022.
//

import UIKit
import CoreData

class DetailsViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    //2 adet kütüphane ekledik bunun sebebi telefonun hafızasından veya kütühanesinden(Galerisinden) verileri(görselleri) alabilmemizi sağlayacak fonksiyonları kullanabilmemiz için gerekli kütüphaneler

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var productName: UITextField!
    @IBOutlet weak var productSale: UITextField!
    @IBOutlet weak var productSize: UITextField!
    @IBOutlet weak var saveButtonControl: UIButton!
    
    var selectedProductName = ""
    var selectedProductUUID : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if selectedProductName != "" { //eğer bir ürünü seçerek buraya geldiyse yapılacak işlem (+ ya tıklayarak gelmemiş)
            //core data seçilen ürün bilgilerini göster
            saveButtonControl.isHidden = true //eğer ürün detay sayfasına gittiyse kaydet butonunu gösterme
            if let uuidString = selectedProductUUID?.uuidString{
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext //delegate i bağlamak için gerekli kod bloğu
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Shoppings") //core datayı bağlamak verileri çekmek için gerekli kod bloğu
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString) //-> id=%@ uuidString e eşit olanları getir. Neyi filtreyeyim ve neye göre filtreleyeyim. Mantıksal bazı sınırlamalar konulur ve arama buna göre yapılır
                fetchRequest.returnsObjectsAsFaults = false
                do{
                    let results = try context.fetch(fetchRequest)
                    if results.count>0{
                        for result in results as! [NSManagedObject]{
                            if let name = result.value(forKey: "isim") as? String{
                                productName.text = name
                            }
                            if let sale = result.value(forKey: "fiyat") as? Int{
                                productSale.text = String(sale)
                                print("ürüne girdi fiyatı göster")
                            }
                            if let size = result.value(forKey: "beden") as? String{
                                productSize.text = size
                            }
                            if let imageData = result.value(forKey: "gorsel") as? Data{
                                let image = UIImage(data: imageData)
                                imageView.image = image
                            }
                        }
                    }
                }catch{
                    print("hata var")
                }
                
                
                
                print(uuidString)
            }
        }else{ //+ ile yebi ürün kaydetme ekranına gittiyse ekrandaki verileri boş göstermesi için aşağıda textleri boş döndük
            saveButtonControl.isHidden = false //kaydet butonunu gizleme
            saveButtonControl.isEnabled = false
            productName.text = ""
            productSale.text = ""
            productSize.text = ""
            print("yeni ürün ekleme ekranına gitti")
        }
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))
        view.addGestureRecognizer(gestureRecognizer) //viewControllera boş bir yere tıklandığında klavyeyi kapatır
        
        imageView.isUserInteractionEnabled = true
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(choseImage)) //fotoğraf seçimi için tıklandığında yapıalcak işlem
        imageView.addGestureRecognizer(imageGestureRecognizer)
    }
    @objc func closeKeyboard(){
        view.endEditing(true)
    }
    @objc func choseImage(){
        let picker = UIImagePickerController()//fotoğraf seçimi için gerekli fonksiyon
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
        saveButtonControl.isEnabled = true
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:  [UIImagePickerController.InfoKey : Any]) { //medya seçmeyi bitirdim (didfinish), kullanıcı seçim yaptıktan sonra kullanulır.
        
        imageView.image = info[.originalImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButton(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate //app delegate deki fonksiyonları kullanabilmek için
        let context = appDelegate.persistentContainer.viewContext
        let Shoppings = NSEntityDescription.insertNewObject(forEntityName: "Shoppings", into: context)//shoppings tablosuna ekleme fonksiyonu için gerekli
        Shoppings.setValue(productName.text!, forKey: "isim") //textboxtaki veriyi istenilen alana set eden kodlar
        if let sale = Int(productSale.text!){ //string ifadeyi integera çevirmek için gerekli
            Shoppings.setValue(sale, forKey: "fiyat")
            print(sale)
        }
        Shoppings.setValue(productSize.text!, forKey: "beden")
                
        //Universal Unique ID
        Shoppings.setValue(UUID(), forKey: "id") //unique değer set etmek için
        let data = imageView.image!.jpegData(compressionQuality: 0.5) //görseller için (0.5 fotoğraf boyutu küçültme)
        Shoppings.setValue(data, forKey: "gorsel")
        
        do{
            try context.save() //veriyi kaydetmesi için try catch yapısı kullanması hata yakalamsı gerekmekte
            print("veri kaydedildi")
        }catch{
            print("Hata Var")
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "veriGirildi"), object: nil)//verileri güncellemek sayfayayı yenilemek için kullanılır.
        self.navigationController?.popViewController(animated: true)//işlem yapıldıktan sonra bir önceki viewControllera döner

    }
    
}
